defmodule AlgoraWeb.Org.DashboardLive do
  use AlgoraWeb, :live_view

  alias Algora.Bounties
  alias Algora.Money
  alias AlgoraWeb.Org.Forms.BountyForm

  def mount(_params, _session, socket) do
    org_id = socket.assigns.current_org.id
    recent_bounties = Bounties.list_bounties(limit: 10)

    changeset =
      %BountyForm{}
      |> BountyForm.changeset(%{
        payment_type: "fixed",
        currency: "USD"
      })

    {:ok,
     socket
     |> assign(:recent_bounties, recent_bounties)
     |> assign_form(changeset)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex-1 space-y-4 p-4 pt-6 sm:p-6 md:p-8">
      <div class="p-6 relative rounded-xl border bg-card text-card-foreground md:gap-8 h-full">
        <div class="flex justify-between items-center">
          <h2 class="text-2xl font-semibold mb-6">Create New Bounty</h2>
          <.button
            type="submit"
            phx-disable-with="Creating..."
            class="relative justify-center cursor-pointer inline-flex items-center space-x-2 text-center font-regular ease-out duration-200 rounded-md outline-none transition-all outline-0 focus-visible:outline-4 focus-visible:outline-offset-1 border bg-primary-400 dark:bg-primary-500 hover:bg-primary/80 dark:hover:bg-primary/50 text-foreground border-primary-500/75 dark:border-primary/30 hover:border-primary-600 dark:hover:border-primary focus-visible:outline-primary-600 data-[state=open]:bg-primary-400/80 dark:data-[state=open]:bg-primary-500/80 data-[state=open]:outline-primary-600 text-xs px-2.5 py-2 h-[32px]"
          >
            Create bounty
          </.button>
        </div>
        <.simple_form for={@form} phx-change="validate" phx-submit="create_bounty" class="space-y-6">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <.label for="title" class="text-sm font-medium mb-2">
                Title
              </.label>
              <.input
                type="text"
                field={@form[:title]}
                placeholder="Brief description of the task"
                required
                class="w-full bg-background border-input rounded-lg"
              />
            </div>
            <div>
              <.label for="task_url" class="text-sm font-medium mb-2">
                Ticket
                <span class="font-normal text-muted-foreground  ">
                  (GitHub, Linear, Figma, Jira, Google Docs...)
                </span>
              </.label>
              <div class="relative">
                <div class="absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none">
                  <.icon
                    name={get_url_icon(@form[:task_url].value)}
                    class="w-5 h-5 text-muted-foreground"
                  />
                </div>
                <.input
                  type="url"
                  field={@form[:task_url]}
                  placeholder="https://github.com/owner/repo/issues/123"
                  required
                  class="w-full pl-10 bg-background border-input rounded-lg"
                />
              </div>
            </div>
          </div>

          <fieldset class="mb-8">
            <legend class="text-sm font-medium text-foreground mb-2">Payment Type</legend>
            <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:payment_type].value == "fixed", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[payment_type]"
                  value="fixed"
                  checked={@form[:payment_type].value == "fixed"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Fixed Amount</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:payment_type].value != "fixed", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Pay upon full completion or reward milestones
                  </span>

                  <div class={"mt-3 transition-opacity duration-200 #{if @form[:payment_type].value != "fixed", do: 'opacity-0 h-0 overflow-hidden', else: 'opacity-100'}"}>
                    <div class="relative">
                      <.input
                        field={@form[:amount]}
                        min="1"
                        step="0.01"
                        placeholder="$1,000"
                        required={@form[:payment_type].value == "fixed"}
                        class="font-display w-full py-1.5 bg-background border-input rounded-lg text-sm text-success font-medium"
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <span class="text-muted-foreground text-sm">USD</span>
                      </div>
                    </div>
                  </div>
                </span>
              </label>

              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:payment_type].value == "hourly", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[payment_type]"
                  value="hourly"
                  checked={@form[:payment_type].value == "hourly"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Hourly Rate</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:payment_type].value != "hourly", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Pay as you go based on hours worked
                  </span>

                  <div class={"mt-3 transition-opacity duration-200 #{if @form[:payment_type].value != "hourly", do: 'opacity-0 h-0 overflow-hidden', else: 'opacity-100'}"}>
                    <div class="grid grid-cols-2 gap-2">
                      <div class="relative">
                        <.input
                          field={@form[:amount]}
                          min="1"
                          step="0.01"
                          placeholder="$75"
                          required={@form[:payment_type].value == "hourly"}
                          class="font-display w-full py-1.5 bg-background border-input rounded-lg text-sm text-success font-medium"
                        />
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                          <span class="text-muted-foreground text-sm">USD/h</span>
                        </div>
                      </div>
                      <div class="relative">
                        <.input
                          field={@form[:expected_hours]}
                          min="1"
                          step="1"
                          placeholder="10"
                          required={@form[:payment_type].value == "hourly"}
                          class="font-display w-full py-1.5 bg-background border-input rounded-lg text-sm"
                        />
                        <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                          <span class="text-muted-foreground text-sm">hours per week</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </span>
              </label>
            </div>
          </fieldset>

          <fieldset class="mb-8">
            <legend class="text-sm font-medium text-foreground mb-2">Share Bounty With</legend>
            <div class="mt-1 grid grid-cols-1 gap-y-6 sm:grid-cols-2 sm:gap-x-4">
              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:sharing_type].value == "private", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[sharing_type]"
                  value="private"
                  checked={@form[:sharing_type].value == "private"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Private Share</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:sharing_type].value != "private", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Share with specific people via email or link
                  </span>

                  <div class={"mt-3 space-y-3 transition-opacity duration-200 #{if @form[:sharing_type].value != "private", do: 'opacity-0 h-0 overflow-hidden', else: 'opacity-100'}"}>
                    <div class="relative">
                      <.input
                        type="text"
                        field={@form[:share_emails]}
                        placeholder="email1@example.com, email2@example.com"
                        class="w-full bg-background border-input rounded-lg"
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
                        <.icon name="tabler-mail" class="w-5 h-5 text-muted-foreground" />
                      </div>
                    </div>
                    <div class="relative">
                      <.input
                        type="text"
                        field={@form[:share_url]}
                        value="https://algora.io/bounties/share/abc123"
                        readonly
                        class="w-full bg-background/50 border-input rounded-lg cursor-pointer"
                      />
                      <div class="absolute inset-y-0 right-0 flex items-center pr-3">
                        <button type="button" class="text-muted-foreground hover:text-foreground">
                          <.icon name="tabler-copy" class="w-5 h-5" />
                        </button>
                      </div>
                    </div>
                  </div>
                </span>
              </label>

              <label class={"relative flex cursor-pointer rounded-lg border p-4 shadow-sm focus:outline-none #{if @form[:sharing_type].value == "platform", do: 'border-primary ring-2 ring-primary bg-background', else: 'border-input bg-background/75'}"}>
                <input
                  type="radio"
                  name="bounty_form[sharing_type]"
                  value="platform"
                  checked={@form[:sharing_type].value == "platform"}
                  class="sr-only"
                />
                <span class="flex flex-1 flex-col">
                  <span class="flex items-center mb-1">
                    <span class="block text-sm font-medium text-foreground">Platform</span>
                    <svg
                      class={"ml-2 h-5 w-5 text-primary #{if @form[:sharing_type].value != "platform", do: 'invisible'}"}
                      viewBox="0 0 20 20"
                      fill="currentColor"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M10 18a8 8 0 1 0 0-16 8 8 0 0 0 0 16Zm3.857-9.809a.75.75 0 0 0-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 1 0-1.06 1.061l2.5 2.5a.75.75 0 0 0 1.137-.089l4-5.5Z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                  <span class="mt-1 text-sm text-muted-foreground">
                    Share with all platform users
                  </span>
                </span>
              </label>
            </div>
          </fieldset>
        </.simple_form>
      </div>
      <.bounties_card current_org={@current_org} bounties={@recent_bounties} />
    </div>
    """
  end

  def bounties_card(assigns) do
    ~H"""
    <div class="group/card relative h-full rounded-xl border bg-card text-card-foreground md:gap-8 overflow-hidden lg:col-span-4">
      <div class="flex justify-between">
        <div class="flex flex-col space-y-1.5 p-6">
          <h3 class="text-2xl font-semibold leading-none tracking-tight">Bounties</h3>
          <p class="text-sm text-gray-500 dark:text-gray-400">Most recently posted bounties</p>
        </div>
        <div class="p-6">
          <.link
            class="whitespace-pre text-sm text-muted-foreground hover:underline hover:brightness-125"
            href={"/org/#{@current_org.handle}/bounties?status=open"}
          >
            View all
          </.link>
        </div>
      </div>
      <div class="p-6 pt-0">
        <ul role="list" class="divide-y divide-white/5">
          <%= for bounty <- @bounties do %>
            <li>
              <.link
                class="group relative flex flex-col items-start gap-x-4 gap-y-2 py-4 sm:flex-row sm:items-center"
                rel="noopener"
                href={"https://github.com/#{bounty.task.owner}/#{bounty.task.repo}/issues/#{bounty.task.number}"}
              >
                <div class="min-w-0 flex-auto">
                  <div class="flex items-center gap-x-3">
                    <div class="flex-none rounded-full p-1 bg-success/10 text-success">
                      <div class="h-2 w-2 rounded-full bg-current"></div>
                    </div>
                    <h2 class="line-clamp-2 min-w-0 text-base font-semibold leading-none text-white group-hover:underline">
                      <%= bounty.task.title %>
                    </h2>
                  </div>
                  <div class="ml-7 mt-px flex items-center gap-x-2 text-xs leading-5 text-gray-400">
                    <div class="flex items-center gap-x-2 md:hidden lg:flex">
                      <span class="truncate">tv#<%= bounty.task.number %></span>
                      <svg viewBox="0 0 2 2" class="h-0.5 w-0.5 flex-none fill-gray-400">
                        <circle cx="1" cy="1" r="1"></circle>
                      </svg>
                    </div>
                    <p class="whitespace-nowrap">
                      <%= Algora.Util.time_ago(bounty.inserted_at) %>
                    </p>
                  </div>
                </div>
                <div class="pl-6">
                  <div class="flex-none rounded-xl px-3 py-1 font-mono text-lg font-extrabold ring-1 ring-inset bg-success/5 text-success ring-success/30">
                    <%= Money.format!(bounty.amount, bounty.currency) %>
                  </div>
                </div>
              </.link>
            </li>
          <% end %>
        </ul>
      </div>
    </div>
    """
  end

  def handle_event("validate", %{"bounty_form" => params}, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("create_bounty", %{"bounty_form" => params}, socket) do
    %{current_user: creator, current_org: owner} = socket.assigns

    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    if changeset.valid? do
      form_data = Ecto.Changeset.apply_changes(changeset)

      # Calculate total amount for hourly payments
      amount =
        if form_data.payment_type == "hourly" do
          Decimal.mult(form_data.amount, Decimal.new(form_data.expected_hours))
        else
          form_data.amount
        end

      # Create params map in the format expected by Bounty.create_changeset
      bounty_params = %{
        "task" => %{
          "url" => form_data.task_url,
          "title" => form_data.title
        },
        "amount" => amount,
        "status" => "open"
      }

      case Bounties.create_bounty(creator, owner, bounty_params) do
        {:ok, _bounty} ->
          {:noreply,
           socket
           |> put_flash(:info, "Bounty created successfully")
           |> push_navigate(to: "/org/#{owner.handle}/bounties")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Error creating bounty")}
      end
    else
      {:noreply,
       socket
       |> assign_form(changeset)
       |> put_flash(:error, "Please fix the errors in the form")}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp get_url_icon(nil), do: "tabler-link"

  defp get_url_icon(url) when is_binary(url) do
    cond do
      String.contains?(url, "github.com") -> "tabler-brand-github"
      String.contains?(url, "figma.com") -> "tabler-brand-figma"
      String.contains?(url, "docs.google.com") -> "tabler-brand-google"
      # String.contains?(url, "linear.app") -> "tabler-brand-linear"
      # String.contains?(url, "atlassian.net") -> "tabler-brand-jira"
      true -> "tabler-link"
    end
  end
end
