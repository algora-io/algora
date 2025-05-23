defmodule Algora.Cloud do
  @moduledoc false

  def top_contributions(github_handles) do
    call(AlgoraCloud, :top_contributions, [github_handles])
  end

  def list_top_matches(opts \\ []) do
    call(AlgoraCloud, :list_top_matches, [opts])
  end

  def list_top_stargazers(opts \\ []) do
    call(AlgoraCloud, :list_top_stargazers, [opts])
  end

  def truncate_matches(org, matches) do
    call(AlgoraCloud, :truncate_matches, [org, matches])
  end

  def count_matches(job) do
    call(AlgoraCloud, :count_matches, [job])
  end

  def get_contribution_score(job, user, contributions_map) do
    call(AlgoraCloud, :get_contribution_score, [job, user, contributions_map])
  end

  def start do
    call(AlgoraCloud, :start, [])
  end

  defp call(module, function, args) do
    if :code.which(module) == :non_existing do
      # TODO: call algora API
      {:error, :not_loaded}
    else
      apply(module, function, args)
    end
  end
end
