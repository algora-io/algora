defmodule AlgoraWeb.Org.Forms.BountyForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :title, :string
    field :task_url, :string
    field :amount, :decimal
    field :expected_hours, :integer
    field :payment_type, :string
    field :currency, :string
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [:title, :task_url, :amount, :expected_hours, :payment_type, :currency])
    |> validate_required([:title, :task_url, :amount, :payment_type, :currency])
    |> validate_number(:amount, greater_than: 0)
    |> validate_expected_hours()
    |> validate_inclusion(:payment_type, ["fixed", "hourly"])
    |> validate_inclusion(:currency, ["USD"])
    |> validate_task_url()
  end

  defp validate_task_url(changeset) do
    validate_change(changeset, :task_url, fn :task_url, url ->
      # You can add more specific GitHub URL validation here
      case URI.parse(url) do
        %URI{scheme: "https", host: "github.com"} -> []
        _ -> [task_url: "must be a valid GitHub issue URL"]
      end
    end)
  end

  defp validate_expected_hours(changeset) do
    if get_field(changeset, :payment_type) == "hourly" do
      changeset
      |> validate_required([:expected_hours])
      |> validate_number(:expected_hours, greater_than: 0)
    else
      changeset
    end
  end
end
