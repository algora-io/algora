defmodule AlgoraWeb.InstallationCallbackController do
  use AlgoraWeb, :controller

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Github
  alias Algora.Organizations
  alias Algora.Workspace

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
        |> redirect(to: redirect_url(conn))

      {:error, _reason} ->
        redirect(conn, to: redirect_url(conn))
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

    case do_handle_installation(user, installation_id) do
      {:ok, _org} ->
        conn
        |> put_flash(:info, if(setup_action == :install, do: "Installation successful!", else: "Installation updated!"))
        |> redirect(to: redirect_url(conn))

      {:error, error} ->
        Logger.error("❌ Installation callback failed: #{inspect(error)}")

        conn
        |> put_flash(:error, "#{inspect(error)}")
        |> redirect(to: redirect_url(conn))
    end
  end

  defp do_handle_installation(user, installation_id) do
    # TODO: replace :last_context with a new :last_installation_target field
    # TODO: handle nil user
    # TODO: handle nil last_context
    with {:ok, access_token} <- Accounts.get_access_token(user),
         {:ok, installation} <- Github.find_installation(access_token, installation_id),
         {:ok, provider_user} <- Workspace.ensure_user(access_token, installation["account"]["login"]),
         {:ok, org} <- Organizations.fetch_org_by(handle: user.last_context),
         {:ok, _} <- Workspace.upsert_installation(installation, user, org, provider_user) do
      {:ok, org}
    end
  end

  defp redirect_url(conn), do: ~p"/org/#{User.last_context(conn.assigns.current_user)}/settings"
end
