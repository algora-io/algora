# Script for populating the database. You can run it as:
#
#     mix ecto.seed <your-github-id>

import Algora.Factory

alias Algora.Repo
alias Algora.Util

require Logger

Application.put_env(:algora, :stripe_impl, Algora.Stripe.SeedImpl)

defmodule Algora.Stripe.SeedImpl do
  @moduledoc false
  @behaviour Algora.Stripe.Behaviour

  @impl true
  def create_invoice(params) do
    {:ok, %{id: "inv_#{Nanoid.generate()}", customer: params.customer}}
  end

  @impl true
  def create_invoice_item(params) do
    {:ok, %{id: "ii_#{Nanoid.generate()}", amount: params.amount}}
  end

  @impl true
  def pay_invoice(_invoice_id, _params) do
    {:ok,
     %{
       id: "inv_#{Nanoid.generate()}",
       paid: true,
       status: "paid"
     }}
  end

  @impl true
  def create_transfer(_params) do
    {:ok, %{id: "tr_#{Nanoid.generate()}"}}
  end
end

github_id =
  case System.argv() do
    [github_id] -> github_id
    _ -> "123456789"
  end

pied_piper = upsert!(:organization, [:email])

erich =
  upsert!(
    :user,
    [:provider, :provider_id],
    %{provider_id: github_id, last_context: pied_piper.handle, is_admin: true}
  )

upsert!(
  :identity,
  [:provider, :provider_id],
  %{
    user_id: erich.id,
    provider: erich.provider,
    provider_id: erich.provider_id,
    provider_email: erich.email,
    provider_login: erich.handle,
    provider_name: erich.name
  }
)

richard =
  upsert!(
    :user,
    [:email],
    %{
      email: "richard@example.com",
      display_name: "Richard Hendricks",
      handle: "richard",
      bio: "CEO of Pied Piper. Creator of the middle-out compression algorithm.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/richard.jpg",
      tech_stack: ["Python", "C++"],
      hourly_rate_min: Money.new!(200, :USD),
      hourly_rate_max: Money.new!(300, :USD),
      hours_per_week: 40
    }
  )

dinesh =
  upsert!(
    :user,
    [:email],
    %{
      email: "dinesh@example.com",
      display_name: "Dinesh Chugtai",
      handle: "dinesh",
      bio: "Lead Frontend Engineer at Pied Piper. Java bad, Python good.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/dinesh.png",
      tech_stack: ["Python", "JavaScript"],
      hourly_rate_min: Money.new!(150, :USD),
      hourly_rate_max: Money.new!(200, :USD),
      hours_per_week: 35
    }
  )

gilfoyle =
  upsert!(
    :user,
    [:email],
    %{
      email: "gilfoyle@example.com",
      display_name: "Bertram Gilfoyle",
      handle: "gilfoyle",
      bio: "Systems Architect. Security. DevOps. Satanist.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/gilfoyle.jpg",
      tech_stack: ["Python", "Rust", "Go", "Terraform"],
      hourly_rate_min: Money.new!(180, :USD),
      hourly_rate_max: Money.new!(250, :USD),
      hours_per_week: 40
    }
  )

jared =
  upsert!(
    :user,
    [:email],
    %{
      email: "jared@example.com",
      display_name: "Jared Dunn",
      handle: "jared",
      bio: "COO of Pied Piper. Former Hooli executive. Excel wizard.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/jared.png",
      tech_stack: ["Python", "SQL"],
      hourly_rate_min: Money.new!(175, :USD),
      hourly_rate_max: Money.new!(225, :USD),
      hours_per_week: 45
    }
  )

carver =
  upsert!(
    :user,
    [:email],
    %{
      email: "carver@example.com",
      display_name: "Kevin 'The Carver'",
      handle: "carver",
      bio:
        "Cloud architecture specialist. If your infrastructure needs a teardown, I'm your guy. Known for my 'insane' cloud architectures and occasional server incidents.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/carver.jpg",
      tech_stack: ["Python", "Go", "Rust", "Terraform"],
      hourly_rate_min: Money.new!(200, :USD),
      hourly_rate_max: Money.new!(300, :USD),
      hours_per_week: 30
    }
  )

pied_piper_members = [erich, richard, dinesh, gilfoyle, jared]

for user <- pied_piper_members do
  upsert!(
    :member,
    [:user_id, :org_id],
    %{user_id: user.id, org_id: pied_piper.id}
  )
end

if customer_id = Algora.config([:stripe, :test_customer_id]) do
  {:ok, cus} = Stripe.Customer.retrieve(customer_id)
  {:ok, pm} = Stripe.PaymentMethod.retrieve(cus.invoice_settings.default_payment_method)

  customer =
    upsert!(
      :customer,
      [:provider, :provider_id],
      %{
        provider_id: cus.id,
        provider_meta: Util.normalize_struct(cus),
        name: cus.name,
        user_id: pied_piper.id
      }
    )

  _payment_method =
    upsert!(
      :payment_method,
      [:provider, :provider_id],
      %{
        provider_id: pm.id,
        provider_meta: Util.normalize_struct(pm),
        provider_customer_id: cus.id,
        customer_id: customer.id
      }
    )
end

if account_id = Algora.config([:stripe, :test_account_id]) do
  {:ok, acct} = Stripe.Account.retrieve(account_id)

  upsert!(
    :account,
    [:provider, :provider_id],
    %{
      provider_id: acct.id,
      provider_meta: Util.normalize_struct(acct),
      name: acct.business_profile.name,
      details_submitted: acct.details_submitted,
      charges_enabled: acct.charges_enabled,
      country: acct.country,
      type: String.to_atom(acct.type),
      user_id: carver.id
    }
  )
end

num_cycles = 20

# Create the contract template
_contract_template =
  insert!(
    :contract,
    %{
      client_id: pied_piper.id,
      start_date: days_from_now(-num_cycles * 7),
      end_date: days_from_now(-(num_cycles - 1) * 7)
    }
  )

# Create the initial contract
initial_contract =
  insert!(
    :contract,
    %{
      contractor_id: carver.id,
      client_id: pied_piper.id,
      start_date: days_from_now(-(num_cycles + 1) * 7),
      end_date: days_from_now(-num_cycles * 7)
    }
  )

{:ok, initial_contract} = Algora.Contracts.fetch_contract(initial_contract.id)

# Prepay the initial contract
{:ok, _txs} = Algora.Contracts.prepay_contract(initial_contract)

# Iterate over the cycles to create timesheets and release & renew contracts
last_contract =
  Enum.reduce_while(1..num_cycles, initial_contract, fn _i, contract ->
    insert!(:timesheet, %{
      contract_id: contract.id,
      hours_worked: Enum.random(35..45),
      inserted_at: contract.end_date
    })

    {:ok, contract} = Algora.Contracts.fetch_contract(contract.id)

    {:ok, {_txs, new_contract}} = Algora.Contracts.release_and_renew_contract(contract)

    {:cont, new_contract}
  end)

insert!(:timesheet, %{
  contract_id: last_contract.id,
  hours_worked: Enum.random(35..45),
  inserted_at: last_contract.end_date
})

thread = insert!(:thread, %{title: "#{pied_piper.name} x #{carver.name}"})

for user <- [pied_piper, carver, erich, richard, dinesh, gilfoyle] do
  insert!(
    :participant,
    %{
      thread_id: thread.id,
      user_id: user.id
    }
  )
end

messages = [
  {erich,
   "hey kevin, i heard you're the best cloud architect in the valley. we need someone to help scale pied piper's infrastructure",
   days_from_now(-4, ~T[09:15:00.000000])},
  {carver,
   "thanks for reaching out! i've been following pied piper's middle-out compression algorithm - really excited about its potential",
   days_from_now(-4, ~T[09:45:00.000000])},
  {richard, "yeah our infrastructure needs help. we're getting crushed by the user growth",
   days_from_now(-4, ~T[14:20:00.000000])},
  {gilfoyle, "the current setup is adequate. but i suppose a second opinion wouldn't hurt",
   days_from_now(-3, ~T[15:05:00.000000])},
  {dinesh, "adequate? the servers catch fire every time we deploy", days_from_now(-3, ~T[15:12:00.000000])},
  {jared, "our uptime metrics have been concerning. i've prepared a spreadsheet tracking all incidents",
   days_from_now(-2, ~T[10:30:00.000000])},
  {carver,
   "i specialize in unconventional but effective solutions. fair warning - my methods might seem chaotic at first",
   days_from_now(-1, ~T[11:45:00.000000])},
  {gilfoyle, "chaos is good. keeps everyone on their toes", days_from_now(-1, ~T[16:20:00.000000])},
  {carver, "give me root access and a week. i'll make your infrastructure bulletproof 🚀",
   days_from_now(0, ~T[09:00:00.000000])}
]

for {sender, content, inserted_at} <- messages do
  insert!(
    :message,
    %{
      thread_id: thread.id,
      sender_id: sender.id,
      content: content,
      inserted_at: inserted_at
    }
  )
end

Logger.info("Contract: #{AlgoraWeb.Endpoint.url()}/org/#{pied_piper.handle}/contracts/#{initial_contract.id}")

repos = [
  {
    "middle-out",
    [
      "Optimize algorithm performance",
      "Add support for new file types",
      "Improve error handling",
      "Implement streaming compression",
      "Add compression statistics API"
    ]
  },
  {
    "pied-piper-web",
    [
      "Fix memory leak in upload handler",
      "Implement new dashboard UI",
      "Add real-time compression stats",
      "Integrate SSO authentication",
      "Build file comparison view"
    ]
  },
  {
    "infra",
    [
      "Scale kubernetes cluster",
      "Implement auto-scaling",
      "Optimize cloud costs",
      "Set up monitoring and alerts",
      "Configure disaster recovery"
    ]
  }
]

for {repo_name, issues} <- repos do
  repo =
    insert!(:repository, %{
      name: repo_name,
      url: "https://github.com/piedpiper/#{repo_name}",
      user_id: pied_piper.id
    })

  for {issue_title, index} <- Enum.with_index(issues, 1) do
    ticket =
      insert!(:ticket, %{
        repository_id: repo.id,
        title: issue_title,
        description: "We need help implementing this feature to improve our platform.",
        number: index,
        url: "https://github.com/piedpiper/#{repo_name}/issues/#{index}"
      })

    amount = Money.new!(Enum.random([500, 1000, 1500, 2000]), :USD)

    claimed = rem(index, 2) > 0
    paid = claimed and rem(index, 3) > 0

    bounty =
      insert!(:bounty, %{
        ticket_id: ticket.id,
        owner_id: pied_piper.id,
        creator_id: richard.id,
        amount: amount,
        status: if(paid, do: :paid, else: :open)
      })

    if not claimed do
      pied_piper_members
      |> Enum.take_random(Enum.random(0..(length(pied_piper_members) - 1)))
      |> Enum.each(fn member ->
        amount = Money.new!(Enum.random([500, 1000, 1500, 2000]), :USD)

        insert!(:bounty, %{
          ticket_id: ticket.id,
          owner_id: member.id,
          creator_id: member.id,
          amount: amount,
          status: :open
        })
      end)
    end

    if claimed do
      claim =
        insert!(:claim, %{
          bounty_id: bounty.id,
          user_id: carver.id,
          status: if(paid, do: :paid, else: :pending),
          title: "Implementation for #{issue_title}",
          description: "Here's my solution to this issue.",
          url: "https://github.com/piedpiper/#{repo_name}/pull/#{index}"
        })

      # Create transaction pairs for paid claims
      if paid do
        debit_id = Nanoid.generate()
        credit_id = Nanoid.generate()

        Repo.transact(fn ->
          insert!(:transaction, %{
            id: debit_id,
            linked_transaction_id: credit_id,
            bounty_id: bounty.id,
            type: :debit,
            status: :succeeded,
            net_amount: amount,
            user_id: pied_piper.id,
            succeeded_at: claim.inserted_at
          })

          insert!(:transaction, %{
            id: credit_id,
            linked_transaction_id: debit_id,
            bounty_id: bounty.id,
            type: :credit,
            status: :succeeded,
            net_amount: amount,
            user_id: carver.id,
            succeeded_at: claim.inserted_at
          })

          {:ok, :ok}
        end)
      end
    end
  end
end

big_head =
  upsert!(
    :user,
    [:email],
    %{
      email: "bighead@example.com",
      display_name: "Nelson Bighetti",
      handle: "bighead",
      bio: "Former Hooli executive. Accidental tech success. Stanford President.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/bighead.jpg",
      tech_stack: ["Python", "JavaScript"],
      country: "IT",
      hourly_rate_min: Money.new!(150, :USD),
      hourly_rate_max: Money.new!(200, :USD),
      hours_per_week: 25
    }
  )

jian_yang =
  upsert!(
    :user,
    [:email],
    %{
      email: "jianyang@example.com",
      display_name: "Jian Yang",
      handle: "jianyang",
      bio: "App developer. Creator of SeeFood and Smokation.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/jianyang.jpg",
      tech_stack: ["Swift", "Python", "TensorFlow"],
      country: "HK",
      hourly_rate_min: Money.new!(125, :USD),
      hourly_rate_max: Money.new!(175, :USD),
      hours_per_week: 35
    }
  )

john =
  upsert!(
    :user,
    [:email],
    %{
      email: "john@example.com",
      display_name: "John Stafford",
      handle: "john",
      bio: "Datacenter infrastructure expert. Rack space optimization specialist.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/john.png",
      tech_stack: ["Perl", "Terraform", "C++", "C"],
      country: "GB",
      hourly_rate_min: Money.new!(140, :USD),
      hourly_rate_max: Money.new!(190, :USD),
      hours_per_week: 40
    }
  )

aly =
  upsert!(
    :user,
    [:email],
    %{
      email: "aly@example.com",
      display_name: "Aly Dutta",
      handle: "aly",
      bio: "Former Hooli engineer. Expert in distributed systems and scalability.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/aly.png",
      tech_stack: ["Java", "Kotlin", "Go"],
      country: "IN",
      hourly_rate_min: Money.new!(160, :USD),
      hourly_rate_max: Money.new!(220, :USD),
      hours_per_week: 35
    }
  )

for user <- [aly, big_head, jian_yang, john] do
  debit_id = Nanoid.generate()
  credit_id = Nanoid.generate()
  amount = Money.new!(Enum.random(1..10) * 10_000, :USD)

  Repo.transact(fn ->
    insert!(:transaction, %{
      id: debit_id,
      linked_transaction_id: credit_id,
      type: :debit,
      status: :succeeded,
      net_amount: amount,
      user_id: pied_piper.id,
      succeeded_at: days_from_now(0)
    })

    insert!(:transaction, %{
      id: credit_id,
      linked_transaction_id: debit_id,
      type: :credit,
      status: :succeeded,
      net_amount: amount,
      user_id: user.id,
      succeeded_at: days_from_now(0)
    })

    {:ok, :ok}
  end)
end

reviews = [
  {richard, carver, -1,
   "His cloud architecture is... unconventional, but it works. Like, really works. Our servers haven't crashed in weeks. Just wish he'd document things better."},
  {gilfoyle, carver, 0,
   "Finally, someone who understands that true system architecture requires embracing chaos. His security implementations are adequately paranoid. Satan would approve."},
  {dinesh, carver, -2,
   "The infrastructure is faster, I'll give him that. But his code comments are borderline offensive and he keeps calling my frontend 'cute'. Still better than our previous setup."},
  {jared, carver, -1,
   "Very efficient contractor! While his methods are somewhat anxiety-inducing, our uptime metrics have improved by 287%. Would recommend (with appropriate warnings)."},
  {richard, aly, -1,
   "Aly's expertise in distributed systems helped us optimize our entire backend. Their Java implementations were surprisingly elegant."},
  {gilfoyle, big_head, -2,
   "Big Head somehow managed to solve our most complex scaling issues by complete accident. I'm still not sure if he knows what he did."},
  {dinesh, jian_yang, -1,
   "Jian Yang's machine learning optimizations were impressive, even though half his comments were in Chinese. The SeeFood integration works flawlessly."},
  {jared, john, 0,
   "John's datacenter expertise saved us thousands in operational costs. His documentation is immaculate and his Perl scripts, while archaic, are incredibly efficient."}
]

for {reviewer, reviewee, rating_delta, content} <- reviews do
  insert!(
    :review,
    %{
      rating: Algora.Reviews.Review.max_rating() + rating_delta,
      content: content,
      visibility: :public,
      contract_id: initial_contract.id,
      organization_id: pied_piper.id,
      reviewer_id: reviewer.id,
      reviewee_id: reviewee.id
    }
  )
end

IO.puts("Contract: #{AlgoraWeb.Endpoint.url()}/org/#{pied_piper.handle}/contracts/#{initial_contract.id}")
