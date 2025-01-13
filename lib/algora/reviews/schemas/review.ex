defmodule Algora.Reviews.Review do
  @moduledoc false
  use Algora.Schema

  alias Algora.Accounts.User
  alias Algora.Activities.Activity

  typed_schema "reviews" do
    field :rating, :integer
    field :content, :string
    field :visibility, Ecto.Enum, values: [:public, :private]

    belongs_to :contract, Algora.Contracts.Contract
    belongs_to :bounty, Algora.Bounties.Bounty
    belongs_to :organization, User
    belongs_to :reviewer, User
    belongs_to :reviewee, User

    has_many :activities, {"review_activities", Activity}, foreign_key: :assoc_id, on_replace: :ignore

    timestamps()
  end

  def changeset(review, attrs) do
    review
    |> cast(attrs, [:rating, :content, :visibility, :contract_id, :reviewer_id, :reviewee_id, :organization_id])
    |> validate_required([:rating, :content, :contract_id, :reviewer_id, :reviewee_id, :organization_id])
    |> validate_number(:rating,
      greater_than_or_equal_to: min_rating(),
      less_than_or_equal_to: max_rating()
    )
    |> generate_id()
  end

  def min_rating, do: 1
  def max_rating, do: 5
end
