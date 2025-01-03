defmodule Algora.Jobs do
  @moduledoc false
  alias Algora.Jobs.Job
  alias Algora.Repo

  def create_job(attrs) do
    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
  end
end
