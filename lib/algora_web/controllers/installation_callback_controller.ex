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

  defp get_followers_count(token, user) do
    if followers_count = user.provider_meta["followers_count"] do
      followers_count
    else
      case Github.get_user(token, user.provider_id) do
        {:ok, user} -> user["followers"]
        _ -> 0
      end
    end
  end

  defp get_total_followers_count(token, users) do
    users
    |> Enum.map(&get_followers_count(token, &1))
    |> Enum.sum()
  end

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
         {:ok, provider_user} <- Workspace.ensure_user(access_token, installation["account"]["login"]) do
      _contributors_res = init_contributors(access_token, installation)
      total_followers_count = get_total_followers_count(access_token, [user, provider_user])

      case user.last_context do
        "preview/" <> ctx ->
          case String.split(ctx, "/") do
            [id, _repo_owner, _repo_name] ->
              existing_org =
                Repo.one(
                  from(u in User,
                    where: u.provider == "github",
                    where: u.provider_id == ^to_string(installation["account"]["id"])
                  )
                )

              {:ok, org} =
                case existing_org do
                  %User{} = org -> {:ok, org}
                  nil -> Repo.fetch(User, id)
                end

              {:ok, _member} =
                case Repo.get_by(Member, user_id: user.id, org_id: org.id) do
                  %Member{} = member -> {:ok, member}
                  nil -> Repo.insert(%Member{id: Nanoid.generate(), user: user, org: org, role: :admin})
                end

              {:ok, org} =
                org
                |> change(
                  handle: Organizations.ensure_unique_org_handle(installation["account"]["login"]),
                  featured: if(org.featured, do: true, else: total_followers_count > featured_follower_threshold()),
                  provider: "github",
                  provider_id: to_string(installation["account"]["id"]),
                  provider_meta: Util.normalize_struct(installation["account"])
                )
                |> Repo.update()

              {:ok, user} =
                user
                |> change(last_context: org.handle)
                |> Repo.update()

              {:ok, _} = Workspace.upsert_installation(installation, user, org, provider_user)

              {:ok, UserAuth.put_current_user(conn, user)}

            _ ->
              {:error, :invalid_last_context}
          end

        last_context ->
          {:ok, org} = Organizations.fetch_org_by(handle: last_context)

          {:ok, org} =
            org
            |> change(featured: if(org.featured, do: true, else: total_followers_count > featured_follower_threshold()))
            |> Repo.update()

          {:ok, _} = Workspace.upsert_installation(installation, user, org, provider_user)
          {:ok, conn}
      end
    end
  end
end
