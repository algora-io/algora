defmodule Algora.Activities.Activity do
  @moduledoc false
  use Algora.Schema

  require Protocol

  @activity_types ~w{
    contract_paid
    contract_prepaid
    contract_created
    contract_renewed
    transaction_status_change
    transaction_created
    transaction_failed
    transaction_processed
    identity_created
    bounty_awarded
    bounty_posted
    bounty_repriced
    claim_submitted
    claim_approved
    tip_awarded
  }a

  typed_schema "activities" do
    field :assoc_id, :string
    field :type, Ecto.Enum, values: @activity_types
    field :visibility, Ecto.Enum, values: [:public, :private, :internal], default: :internal
    field :template, :string
    field :meta, :map, default: %{}
    field :changes, :map, default: %{}
    field :trace_id, :string
    field :notify_users, {:array, :string}, default: []
    field :assoc_name, :string, virtual: true

    belongs_to :user, Algora.Accounts.User
    belongs_to :previous_event, __MODULE__

    timestamps()
  end

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:type, :visibility, :template, :meta, :changes, :trace_id, :user_id, :previous_event_id])
    |> validate_required([:type])
    |> foreign_key_constraint(:assoc_id)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:previous_event_id)
    |> generate_id()
  end

  def build_activity(target, %{meta: %struct{}} = activity) when struct in [Stripe.Error] do
    build_activity(target, %{activity | meta: Algora.Util.normalize_struct(struct)})
  end

  def build_activity(target, activity) do
    target
    |> Ecto.build_assoc(:activities)
    |> changeset(activity)
  end

  def put_activity(target, activity) do
    put_activity(change(target), target, activity)
  end

  def put_activiies(target, activities) do
    put_activities(change(target), target, activities)
  end

  def put_activity(changeset, target, activity) do
    put_activities(changeset, target, [activity])
  end

  def put_activities(%Ecto.Changeset{changes: changes} = changeset, target, activities) do
    put_assoc(
      changeset,
      :activities,
      Enum.map(activities, fn activity ->
        build_activity(target, put_changes(activity, changes))
      end)
    )
  end

  defp put_changes(activity, changes) do
    changes = Map.delete(changes, :activities)
    Map.put(activity, :changes, changes)
  end
end
