defmodule Algora.Cloud do
  @moduledoc false

  def top_contributions(github_handles) do
    call(AlgoraCloud, :top_contributions, [github_handles], [])
  end

  def list_top_matches(opts \\ []) do
    call(AlgoraCloud, :list_top_matches, [opts], [])
  end

  def list_top_stargazers(opts \\ []) do
    call(AlgoraCloud, :list_top_stargazers, [opts], [])
  end

  def truncate_matches(org, matches) do
    call(AlgoraCloud, :truncate_matches, [org, matches], matches)
  end

  def count_matches(job) do
    call(AlgoraCloud, :count_matches, [job], 0)
  end

  def list_heatmaps(user_ids) do
    call(AlgoraCloud.Profiles, :list_heatmaps, [user_ids], [])
  end

  def list_language_contributions_batch(user_ids) do
    call(AlgoraCloud.Profiles, :list_language_contributions_batch, [user_ids], [])
  end

  def sync_heatmap_by(opts \\ []) do
    call(AlgoraCloud.Profiles, :sync_heatmap_by, [opts], {:ok, nil})
  end

  def count_top_matches(opts \\ []) do
    call(AlgoraCloud, :count_top_matches, [opts], 0)
  end

  def get_contribution_score(job, user, contributions_map) do
    call(AlgoraCloud, :get_contribution_score, [job, user, contributions_map], {0, 0})
  end

  def get_job_offer(assigns) do
    call(AlgoraCloud.JobLive, :offer, [assigns], nil)
  end

  def notify_match(attrs) do
    # call(AlgoraCloud.Talent.Jobs.SendJobMatchEmail, :send, [attrs])
    match = Algora.Repo.get_by(Algora.Matches.JobMatch, user_id: attrs.user_id, job_posting_id: attrs.job_posting_id)
    call(AlgoraCloud.EmailScheduler, :schedule_email, [:job_drip, match.id], {:ok, :skipped})
  end

  def notify_candidate_like(_attrs) do
    :ok
    # call(AlgoraCloud.Talent.Jobs.SendCandidateLikeEmail, :send, [attrs])
  end

  def notify_company_like(_match_id) do
    :ok
    # call(AlgoraCloud.EmailScheduler, :schedule_email, [:company_like, match_id])
  end

  def create_admin_task(attrs) do
    call(AlgoraCloud.AdminTasks, :create_admin_task, [attrs], {:ok, nil})
  end

  def create_welcome_task(attrs) do
    call(AlgoraCloud.AdminTasks, :create_welcome_task, [attrs], {:ok, nil})
  end

  def create_origin_event(event, attrs) do
    call(AlgoraCloud.Events, :create_origin_event, [event, attrs], {:ok, nil})
  end

  def presigned do
    call(AlgoraCloud.Constants, :presigned, [], [])
  end

  def candidate_card(assigns) do
    call(AlgoraCloud.Components.CandidateCard, :candidate_card, [assigns], nil)
  end

  def start do
    call(AlgoraCloud, :start, [], [])
  end

  def token! do
    call(AlgoraCloud, :token!, [], nil)
  end

  def token do
    call(AlgoraCloud, :token, [], nil)
  end

  def filter_featured_txs(transactions) do
    call(AlgoraCloud, :filter_featured_txs, [transactions], transactions)
  end

  def ats_event_ids do
    call(AlgoraCloud, :ats_event_ids, [], [])
  end

  def label_ats_event(event) do
    call(AlgoraCloud, :label_ats_event, [event], nil)
  end

  defp call(module, function, args, fallback) do
    if :code.which(module) == :non_existing do
      fallback
    else
      apply(module, function, args)
    end
  end

  defmacro use_if_available(quoted_module, opts \\ []) do
    module = Macro.expand(quoted_module, __CALLER__)

    if Code.ensure_loaded?(module) do
      quote do
        use unquote(quoted_module), unquote(opts)
      end
    end
  end
end
