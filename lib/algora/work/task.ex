defmodule Algora.Work.Task do
  use Ecto.Schema
  import Ecto.Changeset

  alias Algora.Work.Task

  @derive {Inspect, except: [:provider_meta]}
  schema "tasks" do
    field :provider, :string
    field :provider_id, :string
    field :provider_meta, :map

    field :title, :string
    field :description, :string
    field :number, :integer
    field :url, :string

    belongs_to :repository, Algora.Work.Repository
    has_many :bounties, Algora.Bounties.Bounty

    timestamps()
  end

  def changeset(:github, :issue, attrs) do
    %Task{provider: "github", provider_id: to_string(attrs["id"]), provider_meta: attrs}
    |> cast(
      %{
        title: attrs["title"],
        description: attrs["body"],
        number: attrs["number"]
      },
      [:title, :description, :number]
    )
    |> validate_required([:title, :description, :number])
  end

  def changeset(:github, :pull_request, attrs) do
    %Task{provider: "github", provider_id: to_string(attrs["id"]), provider_meta: attrs}
    |> cast(
      %{
        title: attrs["title"],
        description: attrs["body"],
        number: attrs["number"]
      },
      [:title, :description, :number]
    )
    |> validate_required([:title, :description, :number])
  end
end
