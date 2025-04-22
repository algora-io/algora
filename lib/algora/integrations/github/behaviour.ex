defmodule Algora.Github.Behaviour do
  @moduledoc false

  @type token :: String.t()

  @callback get_delivery(String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback list_deliveries(keyword()) :: {:ok, [map()]} | {:error, String.t()}
  @callback redeliver(String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback get_issue(token(), String.t(), String.t(), integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_repository(token(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback get_repository(token(), integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_pull_request(token(), String.t(), String.t(), integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_current_user(token()) :: {:ok, map()} | {:error, String.t()}
  @callback get_current_user_emails(token()) :: {:ok, [map()]} | {:error, String.t()}
  @callback get_user(token(), integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_user_by_username(token(), String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback get_repository_permissions(token(), String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback list_installations(token(), integer()) :: {:ok, map()} | {:error, String.t()}
  @callback find_installation(token(), integer(), integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_installation_token(integer()) :: {:ok, map()} | {:error, String.t()}
  @callback get_installation(integer()) :: {:ok, map()} | {:error, String.t()}
  @callback list_installation_repos(token()) :: {:ok, [map()]} | {:error, String.t()}
  @callback create_issue_comment(token(), String.t(), String.t(), integer(), String.t()) ::
              {:ok, map()} | {:error, String.t()}
  @callback update_issue_comment(token(), String.t(), String.t(), integer(), String.t()) ::
              {:ok, map()} | {:error, String.t()}
  @callback list_user_repositories(token(), String.t(), keyword()) :: {:ok, [map()]} | {:error, String.t()}
  @callback list_repository_events(token(), String.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, String.t()}
  @callback list_repository_comments(token(), String.t(), String.t(), keyword()) :: {:ok, [map()]} | {:error, String.t()}
  @callback list_repository_languages(token(), String.t(), String.t()) :: {:ok, [map()]} | {:error, String.t()}
  @callback list_repository_contributors(token(), String.t(), String.t()) :: {:ok, [map()]} | {:error, String.t()}
  @callback add_labels(token(), String.t(), String.t(), integer(), [String.t()]) :: {:ok, [map()]} | {:error, String.t()}
  @callback create_label(token(), String.t(), String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  @callback get_label(token(), String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  @callback remove_label(token(), String.t(), String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
end
