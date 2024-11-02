defmodule AlgoraWeb.PricingLive do
  use AlgoraWeb, :live_view

  defmodule Plan do
    defstruct [
      :name,
      :description,
      :price,
      :cta_text,
      :popular,
      :previous_tier,
      :features,
      :footnote
    ]
  end

  defmodule Feature do
    defstruct [:name, :detail]
  end

  defmodule ComputeOption do
    defstruct [:name, :cpu, :memory, :price]
  end

  defmodule FaqItem do
    defstruct [:id, :question, :answer]
  end

  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        page_title: "Pricing",
        plans: get_plans(),
        faq_items: get_faq_items(),
        testimonials: get_testimonials(),
        page_scroll: 0,
        active_faq: nil
      )

    {:ok, socket}
  end

  def handle_event("select_plan", %{"plan" => plan_name}, socket) do
    {:noreply, push_navigate(socket, to: "/signup?plan=#{plan_name}")}
  end

  def handle_event("toggle_faq", %{"id" => faq_id}, socket) do
    active_faq = if socket.assigns.active_faq == faq_id, do: nil, else: faq_id
    {:noreply, assign(socket, active_faq: active_faq)}
  end

  def handle_event("select_compute", %{"option" => option}, socket) do
    {:noreply, assign(socket, selected_compute_option: option)}
  end

  # Component: Pricing Card
  def pricing_card(assigns) do
    ~H"""
    <div class={[
      "flex flex-col border xl:border-r-0 last:border-r bg-surface-75 rounded-xl xl:rounded-none first:rounded-l-xl last:rounded-r-xl",
      @plan.popular && "border-foreground-muted !border-2 !rounded-xl xl:-my-8"
    ]}>
      <div class="px-8 xl:px-4 2xl:px-8 pt-6">
        <div class="flex items-center gap-2">
          <div class="flex items-center gap-2 pb-2">
            <h3 class="text-foreground text-2xl font-normal uppercase flex items-center gap-4 font-mono">
              <%= @plan.name %>
            </h3>
            <%= if @plan.popular do %>
              <span class="bg-foreground-light text-background rounded-md py-0.5 px-2 text-[13px] leading-4">
                Most Popular
              </span>
            <% end %>
          </div>
        </div>
        <p class="text-foreground-light mb-4 text-sm 2xl:pr-4">
          <%= @plan.description %>
        </p>
        <button
          phx-click="select_plan"
          phx-value-plan={@plan.name}
          class={[
            "relative w-full cursor-pointer space-x-2 text-center font-regular ease-out duration-200 rounded-md outline-none transition-all outline-0 focus-visible:outline-4 focus-visible:outline-offset-1 border h-[42px] px-4 py-2",
            @plan.popular && "bg-primary text-primary-foreground hover:bg-primary/90",
            !@plan.popular &&
              "bg-background text-foreground hover:bg-accent hover:text-accent-foreground"
          ]}
        >
          <%= @plan.cta_text %>
        </button>
        <div class="text-foreground flex items-baseline text-5xl font-normal lg:text-4xl xl:text-4xl border-b border-default lg:min-h-[175px] py-8 lg:pb-0 lg:pt-10">
          <div class="flex flex-col gap-1">
            <%= if @plan.price do %>
              <div>
                <p class="text-foreground-lighter ml-1 text-[13px] leading-4 font-normal">From</p>
                <div class="flex items-end">
                  <p class="mt-2 pb-1 font-mono text-5xl">$<%= @plan.price %></p>
                  <p class="text-foreground-lighter mb-1.5 ml-1 text-[13px] leading-4">/ month</p>
                </div>
              </div>
            <% else %>
              <div class="flex items-end">
                <p class="mt-2 pb-1 font-mono text-4xl">Custom</p>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      <div class="border-default flex rounded-bl-[4px] rounded-br-[4px] flex-1 flex-col px-8 xl:px-4 2xl:px-8 py-6">
        <p class="text-foreground-lighter text-[13px] mt-2 mb-4">
          <%= if @plan.previous_tier,
            do: "Everything in the #{@plan.previous_tier} Plan, plus:",
            else: "Get started with:" %>
        </p>
        <ul class="text-[13px] flex-1 text-foreground-lighter">
          <%= for feature <- @plan.features do %>
            <li class="flex flex-col py-2 first:mt-0">
              <div class="flex items-center">
                <div class="flex w-6">
                  <.icon name="tabler-check" class="h-4 w-4 text-primary" />
                </div>
                <span class="text-foreground mb-0"><%= feature.name %></span>
              </div>
              <%= if feature.detail do %>
                <p class="ml-6 text-foreground-lighter"><%= feature.detail %></p>
              <% end %>
            </li>
          <% end %>
        </ul>
        <%= if @plan.footnote do %>
          <div class="flex flex-col gap-6 mt-auto prose">
            <div class="space-y-2 mt-12">
              <p class="text-[13px] leading-5 text-foreground-lighter whitespace-pre-wrap mb-0">
                <%= @plan.footnote %>
              </p>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Component: Compute Add-ons
  def compute_addons(assigns) do
    ~H"""
    <div class="mx-auto max-w-7xl">
      <div class="text-center mb-16">
        <h2 class="text-3xl font-bold text-foreground mb-4">Compute Add-ons</h2>
        <p class="text-lg text-muted-foreground">
          Additional compute resources for demanding workloads
        </p>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <%= for option <- @compute_addons do %>
          <div class={[
            "border rounded-lg p-6",
            @selected_option == option.name && "border-primary"
          ]}>
            <button phx-click="select_compute" phx-value-option={option.name} class="w-full text-left">
              <h3 class="text-xl font-semibold text-foreground mb-2"><%= option.name %></h3>
              <div class="space-y-2 text-sm text-muted-foreground">
                <p>CPU: <%= option.cpu %></p>
                <p>Memory: <%= option.memory %></p>
                <p class="text-lg font-semibold text-foreground">$<%= option.price %>/month</p>
              </div>
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Component: Plan Comparison Table
  def plan_comparison_table(assigns) do
    ~H"""
    <div class="container mx-auto py-16">
      <h2 class="text-3xl font-bold text-center text-foreground mb-12">Compare Plans</h2>
      <div class="overflow-x-auto">
        <table class="w-full border-collapse">
          <thead>
            <tr class="border-b">
              <th class="text-left p-4 text-muted-foreground">Features</th>
              <%= for plan <- @plans do %>
                <th class="p-4 text-center text-muted-foreground">
                  <%= plan.name %>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= for feature <- get_comparison_features() do %>
              <tr class="border-b">
                <td class="p-4 text-foreground"><%= feature.name %></td>
                <%= for plan <- @plans do %>
                  <td class="p-4 text-center">
                    <%= if has_feature?(plan, feature) do %>
                      <.icon name="tabler-check" class="h-5 w-5 text-primary mx-auto" />
                    <% else %>
                      <.icon name="tabler-minus" class="h-5 w-5 text-muted-foreground mx-auto" />
                    <% end %>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  # Component: FAQ Section
  def faq_section(assigns) do
    ~H"""
    <div class="container mx-auto py-16">
      <h2 class="text-3xl font-bold text-center text-foreground mb-12">
        Frequently asked questions
      </h2>
      <div class="max-w-3xl mx-auto space-y-4">
        <%= for item <- @faq_items do %>
          <div class="border rounded-lg">
            <button
              phx-click="toggle_faq"
              phx-value-id={item.id}
              class="w-full flex justify-between items-center p-4 text-left"
            >
              <span class="text-foreground font-medium"><%= item.question %></span>
              <.icon
                name="tabler-chevron-down"
                class={[
                  "h-5 w-5 text-muted-foreground transition-transform duration-200",
                  @active_faq == item.id && "transform rotate-180"
                ]}
              />
            </button>
            <%= if @active_faq == item.id do %>
              <div class="p-4 pt-0 text-muted-foreground">
                <%= item.answer %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Data functions
  defp get_plans do
    [
      %Plan{
        name: "Hobby",
        description: "Perfect for small projects and indie developers",
        price: 0,
        cta_text: "Start for Free",
        popular: false,
        features: [
          %Feature{name: "Up to $5,000 in project budgets"},
          %Feature{name: "Algora Network", detail: "15% platform fee"},
          %Feature{name: "Bring Your Own Devs", detail: "5% platform fee"},
          %Feature{name: "Unlimited projects"},
          %Feature{name: "Community support"},
          %Feature{name: "Basic project management tools"},
          %Feature{name: "Pay per milestone"}
        ],
        footnote: "Perfect for testing the waters with smaller projects"
      },
      %Plan{
        name: "Startup",
        description: "For growing companies with larger development needs",
        price: 599,
        cta_text: "Upgrade now",
        popular: true,
        previous_tier: "Hobby",
        features: [
          %Feature{name: "Up to $50,000 in project budgets"},
          %Feature{name: "Algora Network", detail: "15% platform fee"},
          %Feature{name: "Bring Your Own Devs", detail: "5% platform fee"},
          %Feature{name: "Priority support"},
          %Feature{name: "Advanced project management"},
          %Feature{name: "Custom workflows"},
          %Feature{name: "Team collaboration tools"},
          %Feature{name: "Analytics dashboard"},
          %Feature{name: "Job board access"},
          %Feature{name: "Unlimited job postings"}
        ]
      },
      %Plan{
        name: "Enterprise",
        description: "For organizations that need custom solutions and dedicated support",
        price: nil,
        cta_text: "Contact Sales",
        popular: false,
        previous_tier: "Startup",
        features: [
          %Feature{name: "Unlimited project budgets"},
          %Feature{name: "Algora Network", detail: "15% platform fee"},
          %Feature{name: "Bring Your Own Devs", detail: "5% platform fee"},
          %Feature{name: "Dedicated account manager"},
          %Feature{name: "Custom contracts & MSA"},
          %Feature{name: "Advanced security features"},
          %Feature{name: "Custom integrations"},
          %Feature{name: "SLA guarantees"},
          %Feature{name: "Onboarding assistance"},
          %Feature{name: "Training for your team"},
          %Feature{name: "Custom job board"},
          %Feature{name: "ATS integration"}
        ]
      }
    ]
  end

  defp get_compute_addons do
    [
      %ComputeOption{
        name: "Micro",
        cpu: "2 vCPU",
        memory: "1 GB",
        price: 5
      },
      %ComputeOption{
        name: "Small",
        cpu: "4 vCPU",
        memory: "2 GB",
        price: 10
      },
      %ComputeOption{
        name: "Medium",
        cpu: "8 vCPU",
        memory: "4 GB",
        price: 20
      }
    ]
  end

  defp get_faq_items do
    [
      %FaqItem{
        id: "platform-fee",
        question: "How do the platform fees work?",
        answer:
          "We charge 15% for projects using the Algora Network of developers, or 5% if you bring your own developers. This fee helps us maintain the platform, provide payment protection, and ensure quality service."
      },
      %FaqItem{
        id: "budget-limits",
        question: "What happens if my project exceeds the budget limit?",
        answer:
          "You'll need to upgrade to a higher tier to handle larger project budgets. Contact our sales team if you're close to your limit."
      },
      %FaqItem{
        id: "payment-protection",
        question: "How does payment protection work?",
        answer:
          "We hold payments in escrow and release them based on project milestones. This ensures both clients and developers are protected throughout the project lifecycle."
      }
    ]
  end

  defp get_comparison_features do
    [
      %Feature{name: "Project Budget Limit"},
      %Feature{name: "Algora Network Fee"},
      %Feature{name: "Bring Your Own Devs Fee"},
      %Feature{name: "Support Level"},
      %Feature{name: "Team Management"},
      %Feature{name: "Custom Contracts"},
      %Feature{name: "Analytics"}
    ]
  end

  defp has_feature?(plan, feature) do
    Enum.any?(plan.features, &(&1.name == feature.name))
  end

  defp get_testimonials do
    [
      %{
        name: "Sarah Chen",
        role: "CTO at TechCorp",
        avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330",
        quote:
          "Algora has transformed how we hire developers. The quality of talent and the seamless platform experience has made scaling our team effortless."
      },
      %{
        name: "Michael Rodriguez",
        role: "Engineering Lead at StartupX",
        avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
        quote:
          "The developers we found through Algora have become integral parts of our team. The platform's focus on open source contributors really makes a difference."
      },
      %{
        name: "Emily Thompson",
        role: "VP Engineering at ScaleUp Inc",
        avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80",
        quote:
          "What impressed me most was how quickly we could find and onboard qualified developers. Algora's platform streamlines the entire process."
      }
    ]
  end

  def render(assigns) do
    ~H"""
    <main class="relative min-h-screen">
      <div class="relative z-10 pt-8 pb-4 xl:py-16">
        <div class="mx-auto max-w-7xl px-8 text-center sm:px-6 lg:px-8">
          <div class="mx-auto max-w-3xl space-y-2 lg:max-w-none">
            <h1 class="text-4xl font-bold text-popover-foreground">
              Predictable pricing,<br class="block lg:hidden" /> designed to scale
            </h1>
            <p class="text-lg text-muted-foreground">
              Start building for free, collaborate with your team, then scale to millions of users
            </p>
          </div>
        </div>
      </div>

      <div class="mx-auto lg:container lg:px-16 xl:px-12 flex flex-col">
        <div class="relative z-10 mx-auto w-full px-4 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-md grid lg:max-w-none lg:grid-cols-2 xl:grid-cols-3 gap-4 xl:gap-0">
            <%= for plan <- @plans do %>
              <.pricing_card plan={plan} />
            <% end %>
          </div>
        </div>

        <div class="py-24 sm:py-32">
          <div class="mx-auto max-w-7xl px-6 lg:px-8">
            <div class="mx-auto max-w-xl text-center">
              <h2 class="text-3xl font-bold text-popover-foreground mb-4">
                Trusted by companies worldwide
              </h2>
              <p class="text-lg text-muted-foreground">
                See what our customers have to say about their experience with Algora
              </p>
            </div>
            <div class="mx-auto mt-16 grid max-w-2xl grid-cols-1 grid-rows-1 gap-8 text-sm leading-6 text-gray-900 sm:mt-20 sm:grid-cols-2 xl:mx-0 xl:max-w-none xl:grid-cols-3">
              <%= for testimonial <- @testimonials do %>
                <div class="rounded-2xl bg-white/5 p-8 ring-1 ring-white/10">
                  <div class="flex gap-x-3">
                    <img
                      class="object-cover h-10 w-10 rounded-full bg-gray-800"
                      src={testimonial.avatar}
                      alt=""
                    />
                    <div>
                      <div class="font-semibold text-popover-foreground"><%= testimonial.name %></div>
                      <div class="text-muted-foreground"><%= testimonial.role %></div>
                    </div>
                  </div>
                  <blockquote class="mt-6 text-muted-foreground">
                    <%= testimonial.quote %>
                  </blockquote>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <div class="container mx-auto py-16">
          <h2 class="text-3xl font-bold text-center text-popover-foreground mb-12">
            Frequently asked questions
          </h2>
          <div class="max-w-3xl mx-auto space-y-4">
            <%= for item <- @faq_items do %>
              <div class="border rounded-lg">
                <button
                  phx-click="toggle_faq"
                  phx-value-id={item.id}
                  class="w-full flex justify-between items-center p-4 text-left"
                >
                  <span class="text-foreground font-medium"><%= item.question %></span>
                  <.icon
                    name="tabler-chevron-down"
                    class={[
                      "h-5 w-5 text-muted-foreground transition-transform duration-200",
                      @active_faq == item.id && "transform rotate-180"
                    ]}
                  />
                </button>
                <%= if @active_faq == item.id do %>
                  <div class="p-4 pt-0 text-muted-foreground">
                    <%= item.answer %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <div class="bg-card border-t py-32 text-center">
        <div class="mx-auto max-w-7xl px-6 lg:px-8">
          <h2 class="text-3xl font-bold text-card-foreground mb-8">
            <span class="text-muted-foreground">The open source</span>
            <span class="block sm:inline">UpWork alternative.</span>
          </h2>
          <div class="flex justify-center gap-4">
            <.link
              navigate="/signup"
              class="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 bg-primary text-primary-foreground hover:bg-primary/90 h-10 px-4 py-2"
            >
              Start your project
            </.link>
            <.link
              navigate="/contact/sales"
              class="inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2"
            >
              Request a demo
            </.link>
          </div>
        </div>
      </div>
    </main>
    """
  end
end
