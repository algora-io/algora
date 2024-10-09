defmodule Algora.Work.Deliverable do
  use Ecto.Schema
  import Ecto.Changeset

  schema "deliverables" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map
    field :type, Ecto.Enum, values: [:code, :video, :design, :article]
    field :title, :string
    field :description, :string
    field :url, :string

    belongs_to :user, Algora.Accounts.User

    timestamps()
  end

  def changeset(deliverable, attrs) do
    deliverable
    |> cast(attrs, [:provider, :provider_id, :provider_meta, :type, :title, :description, :url])
    |> validate_required([
      :provider,
      :provider_id,
      :provider_meta,
      :type,
      :title,
      :description,
      :url
    ])
  end
end
