defmodule Algora.Settings do
  @moduledoc false
  use Ecto.Schema

  alias Algora.Accounts
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
      [handles: Enum.map(matches, & &1["handle"])]
      |> Accounts.list_developers()
      |> Map.new(fn user -> {user.handle, user} end)

    Enum.flat_map(matches, fn match ->
      if user = Map.get(user_map, match["handle"]) do
        # TODO: N+1
        profile = get_user_profile(user.handle)
        projects = Accounts.list_contributed_projects(user, limit: 2)
        avatar_url = profile["avatar_url"] || user.avatar_url
        hourly_rate = match["hourly_rate"] || profile["hourly_rate"]

        [
          %{
            user: %{user | avatar_url: avatar_url},
            projects: projects,
            badge_variant: match["badge_variant"],
            badge_text: match["badge_text"],
            hourly_rate: if(hourly_rate, do: Money.new(:USD, hourly_rate, no_fraction_if_integer: true))
          }
        ]
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

  def get_org_job_settings(org_id) when is_binary(org_id) do
    case get("org_job_settings:#{org_id}") do
      %{"amount" => amount, "description" => description} when is_binary(description) ->
        %{amount: Algora.MoneyUtils.deserialize(amount), description: description}

      _ ->
        nil
    end
  end

  def set_org_job_settings(org_id, amount, description)
      when is_binary(org_id) and is_binary(description) and is_struct(amount, Money) do
    set("org_job_settings:#{org_id}", %{"amount" => Algora.MoneyUtils.serialize(amount), "description" => description})
  end
end
