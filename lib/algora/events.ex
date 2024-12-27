defmodule Algora.Events do
  import Ecto.Query, warn: false
  alias Algora.Repo
  alias Algora.Events.EventPoller

  def get_event_poller(provider, repo_owner, repo_name) do
    Repo.get_by(EventPoller, provider: provider, repo_owner: repo_owner, repo_name: repo_name)
  end

  def create_event_poller(attrs \\ %{}) do
    %EventPoller{}
    |> EventPoller.changeset(attrs)
    |> Repo.insert()
  end

  def update_event_poller(%EventPoller{} = event_poller, attrs) do
    event_poller
    |> EventPoller.changeset(attrs)
    |> Repo.update()
  end

  def list_active_pollers do
    Repo.all(from p in EventPoller, select: {p.repo_owner, p.repo_name})
  end
end
