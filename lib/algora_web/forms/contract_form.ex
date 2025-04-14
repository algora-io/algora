defmodule AlgoraWeb.Forms.ContractForm do
  @moduledoc false
  use Ecto.Schema
  use AlgoraWeb, :html

  import Ecto.Changeset

  alias Algora.Accounts.User
  alias Algora.Types.USD
  alias Algora.Validations

  embedded_schema do
    field :amount, USD
    field :hourly_rate, USD
    field :hours_per_week, :integer
    field :type, Ecto.Enum, values: [:fixed, :hourly], default: :fixed
    field :title, :string
    field :description, :string
    field :contractor_handle, :string

    embeds_one :contractor, User
  end

  def type_options do
    [{"Fixed", :fixed}, {"Hourly", :hourly}]
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:amount, :hourly_rate, :hours_per_week, :type, :title, :description, :contractor_handle])
    |> validate_required([:contractor_handle])
    |> validate_type_fields()
    |> Validations.validate_github_handle(:contractor_handle, :contractor)
  end

  defp validate_type_fields(changeset) do
    case get_field(changeset, :type) do
      :hourly ->
        changeset
        |> validate_required([:hourly_rate, :hours_per_week])
        |> Validations.validate_money_positive(:hourly_rate)

      _ ->
        changeset
        |> validate_required([:amount])
        |> Validations.validate_money_positive(:amount)
    end
  end

  def contract_form(assigns) do
    ~H"""
    <.form
      id="main-contract-form"
      for={@form}
      phx-submit="create_contract_main"
      phx-change="validate_contract_main"
    >
      <div class="space-y-4">
        <.input label="Title" field={@form[:title]} />
        <.input label="Description (optional)" field={@form[:description]} type="textarea" />
        <div>
          <label class="block text-sm font-semibold leading-6 text-foreground mb-2">
            Payment
          </label>
          <div class="grid grid-cols-2 gap-4" phx-update="ignore" id="main-contract-form-tabs">
            <%= for {label, value} <- type_options() do %>
              <label class={[
                "group relative flex cursor-pointer rounded-lg px-3 py-2 shadow-sm focus:outline-none",
                "border-2 bg-background transition-all duration-200 hover:border-primary hover:bg-primary/10",
                "border-border has-[:checked]:border-primary has-[:checked]:bg-primary/10"
              ]}>
                <.input
                  id={"main-contract-form-type-#{value}"}
                  type="radio"
                  field={@form[:type]}
                  checked={@form[:type].value == value}
                  value={value}
                  class="sr-only"
                  phx-click={
                    %JS{}
                    |> JS.hide(to: "#main-contract-form [data-tab]:not([data-tab=#{value}])")
                    |> JS.show(to: "#main-contract-form [data-tab=#{value}]")
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
        </div>

        <div data-tab="fixed">
          <.input label="Amount" icon="tabler-currency-dollar" field={@form[:amount]} />
        </div>
        <div data-tab="hourly" class="hidden">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <.input label="Hourly rate" icon="tabler-currency-dollar" field={@form[:hourly_rate]} />
            <.input label="Hours per week" field={@form[:hours_per_week]} />
          </div>
        </div>

        <div class="relative">
          <.input
            label="GitHub handle"
            field={@form[:contractor_handle]}
            phx-debounce="500"
            class="pl-10"
          />
          <div class="pointer-events-none absolute left-0 top-9 flex items-center justify-center pl-3 h-7 w-7">
            <.avatar :if={get_field(@form.source, :contractor)} class="h-7 w-7">
              <.avatar_image src={get_field(@form.source, :contractor).avatar_url} />
            </.avatar>
            <.icon name="github" class="h-7 w-7 text-muted-foreground" />
          </div>
        </div>
      </div>
      <div class="pt-4 ml-auto flex gap-4">
        <.button variant="secondary" phx-click="close_share_drawer" type="button">
          Cancel
        </.button>
        <.button type="submit">
          Share Contract <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
        </.button>
      </div>
    </.form>
    """
  end
end
