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
    field :contract_type, Ecto.Enum, values: [:bring_your_own, :marketplace], default: :bring_your_own
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
    |> cast(attrs, [
      :amount,
      :hourly_rate,
      :hours_per_week,
      :type,
      :title,
      :description,
      :contractor_handle,
      :contract_type
    ])
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
        <.input type="hidden" field={@form[:contract_type]} />

        <%= if get_field(@form.source, :contract_type) == :marketplace do %>
          <%= if contractor = get_field(@form.source, :contractor) do %>
            <.card>
              <.card_content>
                <div class="flex items-center gap-4">
                  <.avatar class="h-16 w-16 rounded-full">
                    <.avatar_image src={contractor.avatar_url} alt={contractor.name} />
                    <.avatar_fallback class="rounded-lg">
                      {Algora.Util.initials(contractor.name)}
                    </.avatar_fallback>
                  </.avatar>

                  <div>
                    <div class="flex items-center gap-1 text-base text-foreground">
                      <span class="font-semibold">{contractor.name}</span>
                      {Algora.Misc.CountryEmojis.get(contractor.country)}
                    </div>

                    <div
                      :if={contractor.provider_meta}
                      class="pt-0.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground sm:text-sm"
                    >
                      <.link
                        :if={contractor.provider_login}
                        href={"https://github.com/#{contractor.provider_login}"}
                        target="_blank"
                        class="flex items-center gap-1 hover:underline"
                      >
                        <.icon name="github" class="h-4 w-4" />
                        <span class="whitespace-nowrap">{contractor.provider_login}</span>
                      </.link>
                      <.link
                        :if={contractor.provider_meta["twitter_handle"]}
                        href={"https://x.com/#{contractor.provider_meta["twitter_handle"]}"}
                        target="_blank"
                        class="flex items-center gap-1 hover:underline"
                      >
                        <.icon name="tabler-brand-x" class="h-4 w-4" />
                        <span class="whitespace-nowrap">
                          {contractor.provider_meta["twitter_handle"]}
                        </span>
                      </.link>
                      <div :if={contractor.provider_meta["location"]} class="flex items-center gap-1">
                        <.icon name="tabler-map-pin" class="h-4 w-4" />
                        <span class="whitespace-nowrap">
                          {contractor.provider_meta["location"]}
                        </span>
                      </div>
                      <div :if={contractor.provider_meta["company"]} class="flex items-center gap-1">
                        <.icon name="tabler-building" class="h-4 w-4" />
                        <span class="whitespace-nowrap">
                          {contractor.provider_meta["company"] |> String.trim_leading("@")}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="pt-6 flex flex-wrap gap-2 line-clamp-1">
                  <%= for tech <- contractor.tech_stack do %>
                    <div class="rounded-lg bg-foreground/5 px-2 py-1 text-xs font-medium text-foreground ring-1 ring-inset ring-foreground/25">
                      {tech}
                    </div>
                  <% end %>
                </div>
              </.card_content>
            </.card>
          <% end %>
        <% end %>

        <.input label="Title" field={@form[:title]} />
        <.input label="Description (optional)" field={@form[:description]} type="textarea" />

        <%= if get_field(@form.source, :contract_type) == :bring_your_own do %>
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
        <% end %>

        <%= if get_field(@form.source, :contract_type) == :marketplace do %>
          <.input type="hidden" field={@form[:amount]} />
          <.input type="hidden" field={@form[:hourly_rate]} />
          <.input type="hidden" field={@form[:hours_per_week]} />
          <.input type="hidden" field={@form[:contractor_handle]} />

          <dl class="space-y-4">
            <div class="flex justify-between">
              <dt class="text-foreground">
                Total payment for
                <span class="font-semibold">{get_change(@form.source, :hours_per_week)}</span>
                hours
                <%= if contractor = get_field(@form.source, :contractor) do %>
                  <span class="text-xs text-muted-foreground">
                    ({contractor.name}'s availability)
                  </span>
                <% end %>
                <div class="text-xs text-muted-foreground">
                  (includes all platform and payment processing fees)
                </div>
              </dt>
              <dd class="font-display font-semibold tabular-nums text-lg">
                {Money.to_string!(get_change(@form.source, :amount))}
              </dd>
            </div>
          </dl>
        <% end %>
      </div>
      <div class="pt-4 ml-auto flex gap-4">
        <.button variant="secondary" phx-click="close_share_drawer" type="button">
          Cancel
        </.button>
        <.button type="submit">
          Draft contract <.icon name="tabler-arrow-right" class="-mr-1 ml-2 h-4 w-4" />
        </.button>
      </div>
    </.form>
    """
  end
end
