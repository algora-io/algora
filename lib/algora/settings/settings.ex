defmodule Algora.Settings do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Query

  alias Algora.Accounts
  alias Algora.Accounts.User
  alias Algora.Repo

  @primary_key {:key, :string, []}
  schema "settings" do
    field :value, :map
    timestamps()
  end

  def get(key) do
    case Repo.get(__MODULE__, key) do
      nil -> nil
      config -> config.value
    end
  end

  def set(key, value) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(%{key: key, value: value}, [:key, :value])
    |> Ecto.Changeset.validate_required([:key, :value])
    |> Repo.insert(on_conflict: {:replace, [:value]}, conflict_target: :key)
  end

  def set!(key, value) do
    case set(key, value) do
      {:ok, _} -> :ok
      {:error, reason} -> raise "Failed to set #{key} to #{value}: #{reason}"
    end
  end

  def delete(key) do
    case Repo.get(__MODULE__, key) do
      nil -> {:ok, nil}
      config -> Repo.delete(config)
    end
  end

  def get_featured_developers do
    case get("featured_developers") do
      %{"handles" => handles} when is_list(handles) -> handles
      _ -> nil
    end
  end

  def set_featured_developers(handles) when is_list(handles) do
    set("featured_developers", %{"handles" => handles})
  end

  def get_featured_collabs do
    case get("featured_collabs") do
      %{"handles" => handles} when is_list(handles) -> handles
      _ -> nil
    end
  end

  def set_featured_collabs(handles) when is_list(handles) do
    set("featured_collabs", %{"handles" => handles})
  end

  def set_user_profile(handle, profile) do
    set("user_profile:#{handle}", profile)
  end

  def get_user_profile(handle) do
    get("user_profile:#{handle}")
  end

  def get_org_matches(org) do
    if get_user_profile(org.handle) do
      []
    else
      case get("org_matches:#{org.handle}") do
        %{"matches" => matches} when is_list(matches) ->
          load_matches(matches)

        _ ->
          if tech_stack = List.first(org.tech_stack) do
            get_tech_matches(tech_stack)
          else
            []
          end
      end
    end
  end

  def set_org_matches(org_handle, matches) when is_binary(org_handle) and is_list(matches) do
    set("org_matches:#{org_handle}", %{"matches" => matches})
  end

  def get_job_matches(job) do
    case get("job_matches:#{job.id}") do
      %{"matches" => matches} when is_list(matches) ->
        load_matches(matches)

      _ ->
        [
          tech_stack: job.tech_stack,
          limit: Algora.Cloud.count_matches(job),
          sort_by:
            case get_job_criteria(job) do
              criteria when map_size(criteria) > 0 -> criteria
              _ -> [{"solver", true}]
            end
        ]
        |> Algora.Cloud.list_top_matches()
        |> load_matches_2()
    end
  end

  def get_top_stargazers(job) do
    [
      job: job,
      tech_stack: job.tech_stack,
      limit: 50,
      sort_by: get_job_criteria(job)
    ]
    |> Algora.Cloud.list_top_stargazers()
    |> load_matches_2()
  end

  def set_job_criteria(job_id, criteria) when is_binary(job_id) and is_map(criteria) do
    set("job_criteria:#{job_id}", %{"criteria" => criteria})
  end

  def get_job_criteria(job) do
    cond do
      job.countries != [] ->
        %{"countries" => job.countries}

      job.regions != [] ->
        %{"regions" => job.regions}

      true ->
        case get("job_criteria:#{job.id}") do
          %{"criteria" => criteria} when is_map(criteria) -> criteria
          _ -> %{}
        end
    end
  end

  def set_job_matches(job_id, matches) when is_binary(job_id) and is_list(matches) do
    set("job_matches:#{job_id}", %{"matches" => matches})
  end

  def get_tech_matches(tech) do
    case get("tech_matches:#{String.downcase(tech)}") do
      %{"matches" => matches} when is_list(matches) -> load_matches(matches)
      _ -> []
    end
  end

  def set_tech_matches(tech, matches) when is_binary(tech) and is_list(matches) do
    set("tech_matches:#{String.downcase(tech)}", %{"matches" => matches})
  end

  def load_matches(matches) do
    user_map =
      [handles: Enum.map(matches, & &1["handle"]), limit: :infinity]
      |> Accounts.list_developers()
      |> Enum.filter(& &1.provider_login)
      |> Map.new(fn user -> {user.handle, user} end)

    Enum.flat_map(matches, fn match ->
      if user = Map.get(user_map, match["handle"]) do
        # TODO: N+1
        profile = get_user_profile(user.handle)
        projects = Accounts.list_contributed_projects(user, limit: 2)
        avatar_url = profile["avatar_url"] || user.avatar_url
        hourly_rate = match["hourly_rate"] || profile["hourly_rate"]
        hours_per_week = match["hours_per_week"] || profile["hours_per_week"] || user.hours_per_week

        [
          %{
            user: %{user | avatar_url: avatar_url},
            projects: projects,
            badge_variant: match["badge_variant"],
            badge_text: match["badge_text"],
            hourly_rate: if(hourly_rate, do: Money.new(:USD, hourly_rate, no_fraction_if_integer: true)),
            hours_per_week: hours_per_week
          }
        ]
      else
        []
      end
    end)
  end

  def load_matches_2(matches) do
    user_map =
      [ids: Enum.map(matches, & &1[:user_id]), limit: :infinity]
      |> Accounts.list_developers()
      |> Enum.filter(& &1.provider_login)
      |> Map.new(fn user -> {user.id, user} end)

    Enum.flat_map(matches, fn match ->
      if user = Map.get(user_map, match[:user_id]) do
        [%{user: user, contribution_score: match["contribution_score"]}]
      else
        []
      end
    end)
  end

  def get_blocked_users do
    case get("blocked_users") do
      %{"handles" => handles} when is_list(handles) -> handles
      _ -> []
    end
  end

  def set_blocked_users(handles) when is_list(handles) do
    set("blocked_users", %{"handles" => handles})
  end

  def get_featured_transactions do
    case get("featured_transactions") do
      %{"ids" => ids} when is_list(ids) -> ids
      _ -> nil
    end
  end

  def set_featured_transactions(ids) when is_list(ids) do
    set("featured_transactions", %{"ids" => ids})
  end

  def get_wire_details do
    case get("wire_details") do
      %{"details" => details} when is_map(details) -> details
      _ -> nil
    end
  end

  def set_wire_details(details) when is_map(details) do
    set("wire_details", %{"details" => details})
  end

  def get_subscription_price do
    case get("subscription") do
      %{"price" => %{"amount" => _amount, "currency" => _currency} = price} ->
        Algora.MoneyUtils.deserialize(price)

      _ ->
        nil
    end
  end

  def set_subscription_price(price) do
    set("subscription", %{"price" => Algora.MoneyUtils.serialize(price)})
  end
end
