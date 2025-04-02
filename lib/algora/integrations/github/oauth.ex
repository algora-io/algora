defmodule Algora.Github.OAuth do
  @moduledoc false
  alias Algora.Github

  require Logger

  def exchange_access_token(opts) do
    code = Keyword.fetch!(opts, :code)
    state = Keyword.fetch!(opts, :state)

    state
    |> fetch_exchange_response(code)
    |> fetch_user_info()
    |> fetch_emails()
  end

  defp fetch_exchange_response(state, code) do
    query = [
      state: state,
      code: code,
      client_id: Github.client_id(),
      client_secret: Github.secret()
    ]

    url = "https://github.com/login/oauth/access_token?#{URI.encode_query(query)}"
    headers = [{"Content-Type", "application/json"}, {"accept", "application/json"}]
    request = Finch.build("POST", url, headers)

    with {:ok, %Finch.Response{body: body}} <- Finch.request(request, Algora.Finch),
         {:ok, %{"access_token" => token}} <- Jason.decode(body) do
      {:ok, token}
    else
      {:ok, %{"error" => error}} ->
        Logger.error("failed GitHub exchange #{inspect(error)}")
        {:error, error}

      {:error, _reason} = err ->
        err
    end
  end

  defp fetch_user_info({:error, _reason} = error), do: error

  defp fetch_user_info({:ok, token}) do
    case Github.get_current_user(token) do
      {:ok, info} -> {:ok, %{info: info, token: token}}
      {:error, _reason} = err -> err
    end
  end

  defp fetch_emails({:error, _} = err), do: err

  defp fetch_emails({:ok, user}) do
    case Github.get_current_user_emails(user.token) do
      {:ok, emails} ->
        {:ok, Map.merge(user, %{primary_email: primary_email(emails), emails: emails})}

      {:error, _reason} = err ->
        err
    end
  end

  defp primary_email(emails) do
    Enum.find(emails, fn email -> email["primary"] end)["email"] || Enum.at(emails, 0)
  end
end
