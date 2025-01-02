defmodule Algora.Github.Behaviour do
  @moduledoc false
  @type token :: String.t()
  @type response :: {:ok, map()} | {:error, any()}

  @callback get_issue(token(), String.t(), String.t(), integer()) :: response
  @callback get_repository(token(), String.t(), String.t()) :: response
  @callback get_repository(token(), integer()) :: response
  @callback get_pull_request(token(), String.t(), String.t(), integer()) :: response
  @callback get_current_user(token()) :: response
  @callback get_current_user_emails(token()) :: response
  @callback get_user(token(), integer()) :: response
  @callback get_user_by_username(token(), String.t()) :: response
  @callback get_repository_permissions(token(), String.t(), String.t(), String.t()) :: response
  @callback list_installations(token(), integer()) :: response
  @callback find_installation(token(), integer(), integer()) :: response
  @callback get_installation_token(integer()) :: response
  @callback create_issue_comment(token(), String.t(), String.t(), integer(), String.t()) ::
              response

  @callback list_repository_events(token(), String.t(), String.t(), keyword()) :: response
  @callback list_repository_comments(token(), String.t(), String.t(), keyword()) :: response
end
