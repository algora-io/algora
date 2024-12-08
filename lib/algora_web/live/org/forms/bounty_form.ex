defmodule AlgoraWeb.Org.Forms.BountyForm do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :title, :string
    field :ticket_url, :string
    field :amount, :decimal
    field :expected_hours, :integer
    field :sharing_type, :string
    field :share_emails, :string
    field :share_url, :string
  end

  def changeset(form, attrs \\ %{}) do
    form
    |> cast(attrs, [
      :title,
      :ticket_url,
      :amount,
      :expected_hours,
      :sharing_type,
      :share_emails,
      :share_url
    ])
    |> validate_required([:title, :ticket_url, :amount])
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:sharing_type, ["private", "platform"])
    |> put_default_sharing_type()
    |> validate_ticket_url()
  end

  defp validate_ticket_url(changeset) do
    validate_change(changeset, :ticket_url, fn :ticket_url, url ->
      # You can add more specific GitHub URL validation here
      case URI.parse(url) do
        %URI{scheme: "https", host: "github.com"} -> []
        _ -> [ticket_url: "must be a valid GitHub issue URL"]
      end
    end)
  end

  defp put_default_sharing_type(changeset) do
    if get_field(changeset, :sharing_type) == nil do
      put_change(changeset, :sharing_type, "platform")
    else
      changeset
    end
  end
end
