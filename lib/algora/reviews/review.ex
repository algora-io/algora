defmodule Algora.Reviews.Review do
  use Algora.Model

  @type t() :: %__MODULE__{}

  schema "reviews" do
    field :rating, :integer
    field :content, :string
    field :visibility, Ecto.Enum, values: [:public, :private]

    belongs_to :contract, Algora.Contracts.Contract
    belongs_to :reviewer, Algora.Users.User
    belongs_to :reviewee, Algora.Users.User

    timestamps()
  end

  def changeset(review, attrs) do
    review
    |> cast(attrs, [:rating, :content, :visibility, :contract_id, :reviewer_id, :reviewee_id])
    |> validate_required([:rating, :content, :contract_id, :reviewer_id, :reviewee_id])
    |> validate_number(:rating,
      greater_than_or_equal_to: min_rating(),
      less_than_or_equal_to: max_rating()
    )
  end

  def min_rating(), do: 1
  def max_rating(), do: 5
end
