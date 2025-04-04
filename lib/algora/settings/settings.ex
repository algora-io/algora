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

  def get_org_matches(org) do
    case get("org_matches:#{org.handle}") do
      %{"matches" => matches} when is_list(matches) ->
        user_map =
          [handles: Enum.map(matches, & &1["handle"])]
          |> Accounts.list_developers()
          |> Map.new(fn user -> {user.handle, user} end)

        Enum.flat_map(matches, fn match ->
          if user = Map.get(user_map, match["handle"]) do
            # TODO: N+1
            projects = Accounts.list_contributed_projects(user, limit: 2, tech_stack: org.tech_stack)

            [
              %{
                user: user,
                projects: projects,
                badge_variant: match["badge_variant"],
                badge_text: match["badge_text"]
              }
            ]
          else
            []
          end
        end)

      _ ->
        nil
    end
  end

  def set_org_matches(org_handle, matches) when is_binary(org_handle) and is_list(matches) do
    matches_map =
      Enum.map(matches, fn match ->
        %{
          "handle" => match.handle,
          "badge_variant" => match.badge_variant,
          "badge_text" => match.badge_text
        }
      end)

    set("org_matches:#{org_handle}", %{"matches" => matches_map})
  end
end
