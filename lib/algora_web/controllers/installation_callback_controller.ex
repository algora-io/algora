defmodule AlgoraWeb.InstallationCallbackController do
  use AlgoraWeb, :controller

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Organizations
  alias Algora.Organizations.Member
  alias Algora.Repo
  alias Algora.Util
  alias Algora.Workspace
  alias AlgoraWeb.UserAuth

  require Logger

  def new(conn, params) do
    case validate_query_params(params) do
      {:ok, %{setup_action: :install, installation_id: installation_id}} ->
        handle_installation(conn, :install, installation_id)

      {:ok, %{setup_action: :update, installation_id: installation_id}} ->
        handle_installation(conn, :update, installation_id)

      # TODO: Implement request
      {:ok, %{setup_action: :request}} ->
        conn
        |> put_flash(
          :info,
          "Installation request submitted! The Algora app will be activated upon approval from your organization administrator."
        )
        |> redirect(to: UserAuth.signed_in_path(conn))

      {:error, _reason} ->
        redirect(conn, to: UserAuth.signed_in_path(conn))
    end
  rescue
    error ->
      Logger.error("❌ Installation callback failed: #{inspect(error)}")

      conn
      |> put_flash(:error, "Something went wrong")
      |> redirect(to: UserAuth.signed_in_path(conn))
  end

  defp validate_query_params(params) do
    case params do
      %{"setup_action" => "install", "installation_id" => installation_id} ->
        {:ok, %{setup_action: :install, installation_id: String.to_integer(installation_id)}}

      %{"setup_action" => "update", "installation_id" => installation_id} ->
        {:ok, %{setup_action: :update, installation_id: String.to_integer(installation_id)}}

      %{"setup_action" => "request"} ->
        {:ok, %{setup_action: :request}}

      _ ->
        {:error, :invalid_params}
    end
  end

  defp handle_installation(conn, setup_action, installation_id) do
    user = conn.assigns.current_user

    case do_handle_installation(conn, user, installation_id) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, if(setup_action == :install, do: "Installation successful!", else: "Installation updated!"))
        |> redirect(to: UserAuth.signed_in_path(conn))

      {:error, error} ->
        Logger.error("❌ Installation callback failed: #{inspect(error)}")

        conn
        |> put_flash(:error, "#{inspect(error)}")
        |> redirect(to: UserAuth.signed_in_path(conn))
    end
  end

  defp get_followers_count(_token, %{"followers" => followers}), do: followers

  defp get_followers_count(_token, %{provider_meta: %{"followers" => followers}}), do: followers

  defp get_followers_count(token, %{provider_id: provider_id}) do
    case Github.get_user(token, provider_id) do
      {:ok, user} -> user["followers"]
      _ -> 0
    end
  end

  defp get_followers_count(_token, _user), do: 0

  defp featured_follower_threshold, do: 50

  defp get_top_repo(token, installation) do
    username = installation["account"]["login"]

    with {:ok, repos} <- Github.list_user_repositories(token, username, sort: "pushed", direction: "desc") do
      {:ok,
       repos
       |> Enum.reject(&(&1["fork"] == true))
       |> Enum.sort_by(& &1["stargazers_count"], :desc)
       |> List.first()}
    end
  end

  defp init_contributors(token, installation) do
    with {:ok, repo} when not is_nil(repo) <- get_top_repo(token, installation),
         {:ok, repo} <- Workspace.ensure_repository(token, repo["owner"]["login"], repo["name"]) do
      Workspace.ensure_contributors(token, repo)
    end
  end

  defp do_handle_installation(conn, user, installation_id) do
    # TODO: replace :last_context with a new :last_installation_target field
    # TODO: handle nil user
    # TODO: handle nil last_context
    with {:ok, access_token} <- Accounts.get_access_token(user),
         {:ok, installation} <- Github.find_installation(access_token, installation_id),
         Algora.Admin.alert("New installation for https://github.com/#{installation["account"]["login"]}", :info),
         {:ok, provider_user} <- Github.get_user_by_username(access_token, installation["account"]["login"]),
         total_followers_count = Enum.sum_by([user, provider_user], &get_followers_count(access_token, &1)),
         featured? = total_followers_count > featured_follower_threshold(),
         {:ok, conn, org} <- update_user_and_org(conn, user, installation, featured?),
         {:ok, provider_user} <- Workspace.ensure_user(access_token, installation["account"]["login"]),
         {:ok, _} <- Workspace.upsert_installation(installation, user, org, provider_user) do
      _contributors_res = init_contributors(access_token, installation)
      {:ok, conn}
    end
  end

  defp fetch_or_create_member(user, org) do
    case Repo.get_by(Member, user_id: user.id, org_id: org.id) do
      %Member{} = member -> {:ok, member}
      nil -> Repo.insert(%Member{id: Nanoid.generate(), user: user, org: org, role: :admin})
    end
  end

  defp update_user_and_org(conn, %{last_context: "preview/" <> ctx} = user, installation, featured) do
    with [id, _repo_owner, _repo_name] <- String.split(ctx, "/"),
         existing_org =
           Repo.one(
             from(u in User,
               where: u.provider == "github",
               where: u.provider_id == ^to_string(installation["account"]["id"])
             )
           ),
         {:ok, org} <- if(existing_org, do: {:ok, existing_org}, else: Repo.fetch(User, id)),
         {:ok, _member} <- fetch_or_create_member(user, org),
         {:ok, org} <-
           org
           |> change(
             handle: Organizations.ensure_unique_org_handle(installation["account"]["login"]),
             featured: org.featured || featured,
             provider: "github",
             provider_id: to_string(installation["account"]["id"]),
             provider_login: installation["account"]["login"],
             provider_meta: Util.normalize_struct(installation["account"])
           )
           |> Repo.update(),
         {:ok, user} <- user |> change(last_context: org.handle) |> Repo.update() do
      {:ok, UserAuth.put_current_user(conn, user), org}
    end
  end

  defp update_user_and_org(conn, %{last_context: last_context} = _user, installation, featured) do
    with {:ok, org} <- Organizations.fetch_org_by(handle: last_context),
         {:ok, org} <-
           org
           |> change(
             Map.merge(
               %{featured: org.featured || featured},
               if is_nil(org.provider_id) do
                 %{
                   provider: "github",
                   provider_id: to_string(installation["account"]["id"]),
                   provider_login: installation["account"]["login"],
                   provider_meta: Util.normalize_struct(installation["account"])
                 }
               else
                 %{}
               end
             )
           )
           |> Repo.update() do
      {:ok, conn, org}
    end
  end
end
