defmodule AlgoraWeb.InstallationCallbackController do
  use AlgoraWeb, :controller
  require Logger

  alias Algora.Accounts
  alias Algora.Organizations
  alias Algora.Installations
  alias Algora.Github

  def new(conn, params) do
    case validate_query_params(params) do
      {:ok, %{setup_action: "install", installation_id: installation_id}} ->
        handle_installation(conn, installation_id)

      # TODO: Implement update
      {:ok, %{setup_action: "update"}} ->
        redirect(conn, to: "/user/installations")

      {:error, _reason} ->
        redirect(conn, to: "/user/installations")
    end
  end

  defp validate_query_params(params) do
    case params do
      %{"setup_action" => "install", "installation_id" => installation_id} ->
        {:ok, %{setup_action: "install", installation_id: String.to_integer(installation_id)}}

      %{"setup_action" => "update", "installation_id" => installation_id} ->
        {:ok, %{setup_action: "update", installation_id: String.to_integer(installation_id)}}

      %{"setup_action" => "request"} ->
        {:ok, %{setup_action: "request"}}

      _ ->
        {:error, :invalid_params}
    end
  end

  defp handle_installation(conn, installation_id) do
    user = conn.assigns.current_user

    case do_handle_installation(conn, user, installation_id) do
      {:ok, org} ->
        # TODO: Trigger org joined event
        # trigger_org_joined(org)

        conn
        |> put_flash(:info, "Organization created successfully: #{org.handle}")

        redirect_url = determine_redirect_url(conn, org, user)
        redirect(conn, to: redirect_url)

      {:error, error} ->
        Logger.error("❌ Installation callback failed: #{inspect(error)}")

        conn
        |> put_flash(:error, "#{inspect(error)}")

        redirect(conn, to: "/user/installations")
    end
  end

  defp do_handle_installation(conn, user, installation_id) do
    with {:ok, access_token} <- Accounts.get_access_token(user),
         {:ok, installation} <- Github.find_installation(access_token, installation_id),
         {:ok, github_handle} <- extract_github_handle(installation),
         {:ok, account} <- Github.get_user_by_username(access_token, github_handle),
         {:ok, org} <- upsert_org(conn, user, installation, account),
         {:ok, _} <- upsert_installation(user, org, installation) do
      {:ok, org}
    end
  end

  defp extract_github_handle(%{"account" => %{"login" => login}}), do: {:ok, login}
  defp extract_github_handle(_), do: {:error, 404}

  defp upsert_installation(user, org, installation) do
    case Installations.get_installation_by_provider_id("github", installation["id"]) do
      nil ->
        Installations.create_installation(:github, user, org, installation)

      existing_installation ->
        Installations.update_installation(:github, user, org, existing_installation, installation)
    end
  end

  defp upsert_org(conn, user, installation, account) do
    attrs = %{
      provider: "github",
      provider_id: account["id"],
      provider_login: account["login"],
      provider_meta: account,
      handle: account["login"],
      name: account["name"],
      description: account["bio"],
      website_url: account["blog"],
      twitter_url: get_twitter_url(account),
      avatar_url: account["avatar_url"],
      # TODO:
      active: true,
      featured: account["type"] != "User",
      github_handle: account["login"]
    }

    case Organizations.get_org_by_handle(account["login"]) do
      nil -> create_org(conn, user, attrs, installation)
      existing_org -> update_org(conn, user, existing_org, attrs, installation)
    end
  end

  # TODO: handle conflicting handles
  defp create_org(_conn, user, attrs, _installation) do
    # TODO: trigger org joined event
    # trigger_org_joined(org)
    with {:ok, org} <- Organizations.create_organization(attrs),
         {:ok, _} <- Organizations.create_member(org, user, :admin) do
      {:ok, org}
    end
  end

  defp update_org(_conn, _user, existing_org, attrs, _installation) do
    with {:ok, _} <- Organizations.update_organization(existing_org, attrs) do
      {:ok, existing_org}
    end
  end

  defp determine_redirect_url(_conn, _org, _user) do
    # TODO: Implement
    "/user/installations"
  end

  defp get_twitter_url(%{twitter_username: username}) when is_binary(username) do
    "https://twitter.com/#{username}"
  end

  defp get_twitter_url(_), do: nil
end
