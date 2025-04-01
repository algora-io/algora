defmodule AlgoraWeb.Forms.BountyForm do
  @moduledoc false
  use Ecto.Schema
  use AlgoraWeb, :live_view

  import Ecto.Changeset

  alias Algora.Types.USD
  alias Algora.Validations

  embedded_schema do
    field :url, :string
    field :amount, USD
    field :visibility, Ecto.Enum, values: [:community, :exclusive, :public], default: :public
    field :shared_with, {:array, :string}, default: []
    field :type, Ecto.Enum, values: [:github, :custom], default: :github
    field :title, :string
    field :description, :string

    embeds_one :ticket_ref, TicketRef, primary_key: false do
      field :owner, :string
      field :repo, :string
      field :number, :integer
      field :type, :string
    end
  end

  def type_options do
    [{"GitHub issue", "github"}, {"Custom", "custom"}]
  end

  def changeset(form, params) do
    form
    |> cast(params, [:url, :amount, :visibility, :shared_with, :type, :title, :description])
    |> validate_required([:amount, :visibility, :shared_with])
    |> validate_type_fields()
    |> Validations.validate_money_positive(:amount)
    |> Validations.validate_ticket_ref(:url, :ticket_ref)
    |> validate_subset(:type, Enum.map(type_options(), &elem(&1, 1)))
  end

  defp validate_type_fields(changeset) do
    case get_field(changeset, :type) do
      "custom" -> validate_required(changeset, [:title, :description])
      _ -> validate_required(changeset, [:url])
    end
  end

  def bounty_form(assigns) do
    ~H"""
    <.form id="main-bounty-form" for={@main_bounty_form} phx-submit="create_bounty">
      <div class="space-y-4">
        <.input type="hidden" name="main_bounty_form[visibility]" value="exclusive" />
        <%!-- <.input
              type="hidden"
              name="main_bounty_form[shared_with][]"
              value={
                case @selected_developer do
                  %User{handle: nil, provider_id: provider_id} -> [to_string(provider_id)]
                  %User{id: id} -> [id]
                end
              }
            /> --%>

        <div class="grid grid-cols-2 gap-4">
          <%= for {label, value} <- type_options() do %>
            <label class={[
              "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
              "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
              "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
            ]}>
              <.input
                type="radio"
                field={@main_bounty_form[:type]}
                checked={to_string(get_field(@main_bounty_form.source, :type)) == value}
                value={value}
                class="sr-only"
                phx-click={
                  %JS{}
                  |> JS.hide(to: "#main-bounty-form [data-tab]")
                  |> JS.show(to: "#main-bounty-form [data-tab=#{value}]")
                }
              />
              <span class="flex flex-1 items-center justify-between">
                <span class="text-sm font-medium">{label}</span>
                <.icon
                  name="tabler-check"
                  class="invisible size-5 text-primary group-has-[:checked]:visible"
                />
              </span>
            </label>
          <% end %>
        </div>

        <div
          data-tab="github"
          class={if to_string(get_field(@main_bounty_form.source, :type)) != "github", do: "hidden"}
        >
          <.input
            label="URL"
            field={@main_bounty_form[:url]}
            placeholder="https://github.com/owner/repo/issues/123"
          />
        </div>

        <div
          data-tab="custom"
          class={
            classes([
              to_string(get_field(@main_bounty_form.source, :type)) != "custom" && "hidden",
              "space-y-4"
            ])
          }
        >
          <.input
            label="Title"
            field={@main_bounty_form[:title]}
            placeholder="Brief description of the bounty"
          />
          <.input
            label="Description"
            field={@main_bounty_form[:description]}
            type="textarea"
            placeholder="Requirements and acceptance criteria"
          />
        </div>

        <.input label="Amount" icon="tabler-currency-dollar" field={@main_bounty_form[:amount]} />
      </div>
      <div class="pt-4 ml-auto flex gap-4">
        <.button variant="secondary" phx-click="close_share_drawer" type="button">
          Cancel
        </.button>
        <.button type="submit">
          Share Bounty <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
        </.button>
      </div>
    </.form>
    """
  end
end
