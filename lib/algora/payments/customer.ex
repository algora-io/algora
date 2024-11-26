defmodule Algora.Payments.Customer do
  use Algora.Model

  @type t() :: %__MODULE__{}

  @derive {Inspect, except: [:provider_meta]}
  schema "customers" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :name, :string
    field :region, Ecto.Enum, values: [:US, :EU]

    belongs_to :user, Algora.Users.User
    has_many :transactions, Algora.Payments.Transaction

    timestamps()
  end

  def changeset(customer, attrs) do
    customer
    |> cast(attrs, [:user_id, :provider, :provider_id, :provider_meta, :name, :region])
    |> validate_required([:user_id, :provider, :provider_id, :provider_meta, :name, :region])
  end
end
