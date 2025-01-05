defmodule Algora.Workspace.Jobs.UpdateRepositoryOgImage do
  @moduledoc false
  use Oban.Worker, queue: :github_og_image

  alias Algora.Repo
  alias Algora.Workspace.Repository

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"repository_id" => repository_id}}) do
    repository =
      Repository
      |> Repo.get(repository_id)
      |> Repo.preload(:user)

    case repository do
      nil -> {:error, :not_found}
      repository -> update_og_image(repository)
    end
  end

  defp update_og_image(repository) do
    repo_owner = repository.user.provider_login
    repo_name = repository.name
    object = "repositories/#{repo_owner}/#{repo_name}/og.png"

    req = Finch.build(:get, repository.og_image_url)

    with {:ok, %Finch.Response{body: body}} <- Finch.request(req, Algora.Finch),
         {:ok, _} <- Algora.S3.upload(body, object, content_type: "image/png"),
         url = Algora.S3.bucket_url() <> "/" <> object,
         {:ok, updated_repository} <- update_repository_url(repository, url) do
      {:ok, updated_repository}
    else
      error ->
        Logger.error("Failed to fetch/upload image for #{repo_owner}/#{repo_name}: #{inspect(error)}")
        error
    end
  end

  defp update_repository_url(repository, url) do
    repository
    |> Ecto.Changeset.change(%{
      og_image_url: url,
      og_image_updated_at: DateTime.utc_now()
    })
    |> Repo.update()
  end
end
