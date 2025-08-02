defmodule Algora.Workspace.Jobs.SyncUser do
  @moduledoc false
  use Oban.Worker,
    queue: :internal_par,
    max_attempts: 3

  import Ecto.Changeset

  alias Algora.Github
  alias Algora.Repo
  alias Algora.Workspace

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_id" => provider_id}}) do
    token = Github.TokenPool.get_token()

    with {:ok, data} <- Github.get_user(token, provider_id),
         {:ok, user} <- Workspace.ensure_user_by_provider_id(token, data["id"]) do
      user
      |> change(%{
        display_name: data["name"],
        location: data["location"],
        provider_meta: data,
        provider_login: data["login"]
      })
      |> Repo.update()
    end
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"provider_login" => provider_login}}) do
    token = Github.TokenPool.get_token()

    with {:ok, data} <- Github.get_user_by_username(token, provider_login),
         {:ok, user} <- Workspace.ensure_user_by_provider_id(token, data["id"]) do
      user
      |> change(%{
        display_name: data["name"],
        location: data["location"],
        provider_meta: data,
        provider_login: data["login"]
      })
      |> Repo.update()
    end
  end
end
