defmodule AlgoraEvent.Company do

  defstruct [
    uid: nil,

    # Registration & Onboarding
    joined_at: nil,
    card_saved_at: nil,
    last_active_at: nil,
    visit_count: 0,

    # Job Status
    job_status: nil,
    job_created_at: nil,
    job_published_at: nil,

    # Contract Metrics
    total_contracts: 0,
    active_contracts: 0,
    prepauid_contracts: 0,
    released_contracts: 0,
    renewed_contracts: 0,
    disputed_contracts: 0,

    # Time to Fill
    first_contract_created_at: nil,
    first_contract_filled_at: nil,

    # Aggregate Contract Metrics
    total_matches: 0,
    total_impressions: 0,
    unique_impressions: 0,
    total_clicks: 0
  ]

  import AlgoraEvent.Application, only: [dispatch: 1]
  alias AlgoraEvent.Company.{Commands,Events}
  alias AlgoraEvent.Store

  def uid(id), do: "company:#{id}" ## todo(ty) namespacing with schema?

  def latest_events(start_version \\ -1, count \\ 20) do
    Store.read_all_streams_backward(start_version, count)
  end

  def latest_events_for_company(id, start_version \\ -1, count \\ 20) do
    Store.read_stream_backward(uid(id), start_version, count)
  end

  def events(start_version \\ 0, count \\ 20) do
    Store.read_all_streams_forward(start_version, count)
  end

  def events_for_company(id, start_version \\ 0, count \\ 20) do
    Store.read_stream_forward(uid(id), start_version, count)
  end

  def subscribe(id) do
    Store.subscribe(uid(id))
  end

  def create!(id) do
    dispatch %Commands.Create{uid: uid(id)}
  end

  def visit!(id, user) do
    dispatch %Commands.Visit{uid: uid(id), user: user}
  end

  # only create if joined at nil
  def execute(%__MODULE__{joined_at: nil}, %Commands.Create{uid: uid}) do
    %Events.Created{uid: uid}
  end

  # ignore other events until joined at
  def execute(%__MODULE__{joined_at: nil}, _other_command) do
    nil
  end

  # ignore create when joined at exists
  def execute(%__MODULE__{} = state, %Commands.Create{}) do
    nil
  end

  # create an event for every visit
  def execute(%__MODULE__{visit_count: visit_count}, %Commands.Visit{uid: uid, user: user}) do
    %Events.Visited{uid: uid, visit_count: visit_count, user: user}
  end

  def apply(%__MODULE__{} = state, %Events.Created{}) do
    datetime = DateTime.utc_now
    %__MODULE__{state | joined_at: datetime, last_active_at: datetime}
  end

  def apply(%__MODULE__{} = state, %Events.Visited{visit_count: visit_count}) do
    %__MODULE__{state | visit_count: visit_count + 1}
  end

end
