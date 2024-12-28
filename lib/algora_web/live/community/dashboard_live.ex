defmodule AlgoraWeb.Community.DashboardLive do
  use AlgoraWeb, :live_view

  require Logger

  import Ecto.Changeset
  import AlgoraWeb.Components.Achievement
  import AlgoraWeb.Components.Bounties
  import AlgoraWeb.Components.Experts

  alias Algora.Bounties
  alias Algora.Extensions.Ecto.Validations
  alias Algora.Users
  alias Algora.Workspace

  defmodule BountyForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :url, :string
      field :amount, Algora.Extensions.Ecto.USD

      embeds_one :ticket_ref, TicketRef, primary_key: false do
        field :owner, :string
        field :repo, :string
        field :number, :integer
        field :type, :string
      end
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [:url, :amount])
      |> validate_required([:url, :amount])
      |> Validations.validate_money_positive(:amount)
      |> Validations.validate_ticket_ref(:url, :ticket_ref)
    end
  end

  defmodule TipForm do
    use Ecto.Schema
    import Ecto.Changeset

    embedded_schema do
      field :github_handle, :string
      field :amount, Algora.Extensions.Ecto.USD
    end

    def changeset(form, attrs \\ %{}) do
      form
      |> cast(attrs, [:github_handle, :amount])
      |> validate_required([:github_handle, :amount])
      |> Validations.validate_money_positive(:amount)
    end
  end

  def mount(_params, _session, socket) do
    tech_stack = "Swift"

    if connected?(socket) do
      Bounties.subscribe()
    end

    {:ok,
     socket
     |> assign(:bounty_form, to_form(BountyForm.changeset(%BountyForm{}, %{})))
     |> assign(:tip_form, to_form(TipForm.changeset(%TipForm{}, %{})))
     |> assign(:experts, list_experts(tech_stack) |> Enum.take(6))
     |> assign(:tech_stack, [tech_stack])
     |> assign(:hours_per_week, 40)
     |> assign_tickets()
     |> assign_achievements()}
  end

  def handle_info(:bounties_updated, socket) do
    {:noreply, assign_tickets(socket)}
  end

  def render(assigns) do
    ~H"""
    <div class="lg:pr-96">
      <div class="container max-w-7xl mx-auto p-8 space-y-8">
        <.section>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
            {create_bounty(assigns)}
            {create_tip(assigns)}
          </div>
        </.section>

        <.section title="Open bounties" subtitle={"Bounties pooled from the #{@tech_stack} community"}>
          <.bounties tickets={@tickets} />
        </.section>

        <.section :if={@experts != []} title={"#{@tech_stack} experts"} link={~p"/experts"}>
          <ul class="flex flex-col gap-8 md:grid md:grid-cols-2 xl:grid-cols-3">
            <.experts experts={@experts} />
          </ul>
        </.section>
      </div>
    </div>
    {sidebar(assigns)}
    """
  end

  defp create_bounty(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <div class="flex items-center gap-3">
          <.icon name="tabler-diamond" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Post a bounty</h2>
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@bounty_form} phx-submit="create_bounty">
          <div class="flex flex-col gap-6">
            <.input
              label="URL"
              field={@bounty_form[:url]}
              placeholder="https://github.com/swift-lang/swift/issues/1337"
            />
            <.input label="Amount" icon="tabler-currency-dollar" field={@bounty_form[:amount]} />
            <p class="text-sm text-muted-foreground">
              <span class="font-semibold">Tip:</span>
              You can also create bounties directly on
              GitHub by commenting <code class="px-1 py-0.5 text-success">/bounty $100</code>
              on any issue.
            </p>
            <div class="flex justify-end gap-4">
              <.button>Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp create_tip(assigns) do
    ~H"""
    <.card>
      <.card_header>
        <div class="flex items-center gap-3">
          <.icon name="tabler-gift" class="h-8 w-8" />
          <h2 class="text-2xl font-semibold">Tip a developer</h2>
        </div>
      </.card_header>
      <.card_content>
        <.simple_form for={@tip_form} phx-submit="create_tip">
          <div class="flex flex-col gap-6">
            <.input label="GitHub handle" field={@tip_form[:github_handle]} placeholder="jsmith" />
            <.input label="Amount" icon="tabler-currency-dollar" field={@tip_form[:amount]} />
            <p class="text-sm text-muted-foreground">
              <span class="font-semibold">Tip:</span>
              You can also create tips directly on
              GitHub by commenting <code class="px-1 py-0.5 text-success">/tip $100 @username</code>
              on any pull request.
            </p>
            <div class="flex justify-end gap-4">
              <.button>Submit</.button>
            </div>
          </div>
        </.simple_form>
      </.card_content>
    </.card>
    """
  end

  defp sidebar(assigns) do
    ~H"""
    <aside class="fixed bottom-0 right-0 top-16 hidden w-96 overflow-y-auto border-l border-border bg-background p-4 pt-6 lg:block sm:p-6 md:p-8 scrollbar-thin">
      <div class="flex items-center justify-between">
        <h2 class="text-xl font-semibold leading-none tracking-tight">Getting started</h2>
      </div>
      <nav class="pt-6">
        <ol role="list" class="space-y-6">
          <%= for achievement <- @achievements do %>
            <li>
              <.achievement achievement={achievement} />
            </li>
          <% end %>
        </ol>
      </nav>
    </aside>
    """
  end

  def handle_event("create_bounty", %{"bounty_form" => params}, socket) do
    changeset =
      %BountyForm{}
      |> BountyForm.changeset(params)
      |> Map.put(:action, :validate)

    with %{valid?: true} <- changeset,
         {:ok, _} <-
           Bounties.create_bounty(%{
             creator: socket.assigns.current_user,
             owner: socket.assigns.current_user,
             amount: get_field(changeset, :amount),
             ticket_ref: get_field(changeset, :ticket_ref)
           }) do
      {:noreply,
       socket
       |> assign_achievements()
       |> put_flash(:info, "Bounty created")}
    else
      %{valid?: false} ->
        {:noreply, socket |> assign(:bounty_form, to_form(changeset))}

      {:error, :already_exists} ->
        {:noreply,
         socket |> put_flash(:warning, "You have already created a bounty for this ticket")}

      {:error, _reason} ->
        {:noreply, socket |> put_flash(:error, "Something went wrong")}
    end
  end

  def handle_event("create_tip", %{"tip_form" => params}, socket) do
    changeset =
      %TipForm{}
      |> TipForm.changeset(params)
      |> Map.put(:action, :validate)

    with %{valid?: true} <- changeset,
         {:ok, token} <- Users.get_access_token(socket.assigns.current_user),
         {:ok, recipient} <- Workspace.ensure_user(token, get_field(changeset, :github_handle)),
         {:ok, checkout_url} <-
           Bounties.create_tip(%{
             creator: socket.assigns.current_user,
             owner: socket.assigns.current_user,
             recipient: recipient,
             amount: get_field(changeset, :amount)
           }) do
      {:noreply,
       socket
       |> redirect(external: checkout_url)}
    else
      %{valid?: false} ->
        {:noreply, socket |> assign(:tip_form, to_form(changeset))}

      {:error, reason} ->
        Logger.error("Failed to create tip: #{inspect(reason)}")
        {:noreply, socket |> put_flash(:error, "Something went wrong")}
    end
  end

  defp assign_tickets(socket) do
    socket
    |> assign(
      :tickets,
      Bounties.TicketView.list(status: :open, tech_stack: [socket.assigns.tech_stack], limit: 100) ++
        sample_tickets()
    )
  end

  # TODO: implement this
  defp assign_achievements(socket) do
    socket
    |> assign(:achievements, [
      %{status: :completed, name: "Personalize Algora"},
      %{status: :current, name: "Create a bounty"},
      %{status: :upcoming, name: "Reward a bounty"},
      %{status: :upcoming, name: "Contract a #{socket.assigns.tech_stack} developer"},
      %{status: :upcoming, name: "Complete a contract"}
    ])
  end

  # TODO: remove this once we have real data
  def sample_tickets do
    [
      %{
        total_bounty_amount: Money.new(300, :USD, no_fraction_if_integer: true),
        url: "https://github.com/tuist/tuist/issues/6456",
        title: "Generate Objective C resources for internal targets",
        repository: %{
          owner: %{login: "tuist"},
          name: "tuist"
        },
        number: 6456,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/38419084?v=4",
              handle: "tuist",
              provider_login: "tuist"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(300, :USD, no_fraction_if_integer: true),
        url: "https://github.com/tuist/tuist/issues/6048",
        title: "Support for `.xcstrings` catalog",
        repository: %{
          owner: %{login: "tuist"},
          name: "tuist"
        },
        number: 6048,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/38419084?v=4",
              handle: "tuist",
              provider_login: "tuist"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(200, :USD, no_fraction_if_integer: true),
        url: "https://github.com/tuist/tuist/issues/5920",
        title: "Add support for building, running, and testing multi-platform targets",
        repository: %{
          owner: %{login: "tuist"},
          name: "tuist"
        },
        number: 5920,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/38419084?v=4",
              handle: "tuist",
              provider_login: "tuist"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(100, :USD, no_fraction_if_integer: true),
        url: "https://github.com/Cap-go/capacitor-updater/issues/411",
        title: "bug: Allow setup when apply update like in code push",
        repository: %{
          owner: %{login: "Cap-go"},
          name: "capacitor-updater"
        },
        number: 411,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/97002524?s=200&v=4",
              handle: "Cap-go",
              provider_login: "Cap-go"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(100, :USD, no_fraction_if_integer: true),
        url: "https://github.com/tuist/tuist/issues/268",
        title: "Add support for customizing project groups",
        repository: %{
          owner: %{login: "tuist"},
          name: "tuist"
        },
        number: 268,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/38419084?v=4",
              handle: "tuist",
              provider_login: "tuist"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(100, :USD, no_fraction_if_integer: true),
        url: "https://github.com/tuist/tuist/issues/5912",
        title: "Autogenerate Test targets from Package.swift dependencies",
        repository: %{
          owner: %{login: "tuist"},
          name: "tuist"
        },
        number: 5912,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/38419084?v=4",
              handle: "tuist",
              provider_login: "tuist"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(100, :USD, no_fraction_if_integer: true),
        url: "https://github.com/tuist/tuist/issues/5925",
        title: "TargetScript output files are ignored if the files don't exist at generate time",
        repository: %{
          owner: %{login: "tuist"},
          name: "tuist"
        },
        number: 5925,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/38419084?v=4",
              handle: "tuist",
              provider_login: "tuist"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(100, :USD, no_fraction_if_integer: true),
        url: "https://github.com/tuist/tuist/issues/5552",
        title: "Remove annoying warning \"No files found at:\" for glob path",
        repository: %{
          owner: %{login: "tuist"},
          name: "tuist"
        },
        number: 5552,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/38419084?v=4",
              handle: "tuist",
              provider_login: "tuist"
            }
          }
        ]
      },
      %{
        total_bounty_amount: Money.new(100, :USD, no_fraction_if_integer: true),
        url: "https://github.com/Cap-go/capgo/issues/229",
        title: "Find a better way to block google play test device",
        repository: %{
          owner: %{login: "Cap-go"},
          name: "capgo"
        },
        number: 229,
        bounty_count: 1,
        top_bounties: [
          %{
            owner: %{
              avatar_url: "https://avatars.githubusercontent.com/u/97002524?s=200&v=4",
              handle: "Cap-go",
              provider_login: "Cap-go"
            }
          }
        ]
      }
    ]
  end
end
