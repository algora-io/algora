# Script for populating the database. You can run it as:
#
#     mix ecto.seed <your-github-id>

require Logger
import Algora.Factory
alias Algora.{Repo, Util}

Application.put_env(:algora, :stripe_impl, Algora.Stripe.SeedImpl)

defmodule Algora.Stripe.SeedImpl do
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
end

defmodule Seeds do
  def upsert_opts(conflict_target) do
    [
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: conflict_target,
      returning: true
    ]
  end
end

github_id =
  case System.argv() do
    [github_id] -> github_id
    _ -> "123456789"
  end

erich =
  Repo.insert!(
    build(:user, %{provider_id: github_id}),
    Seeds.upsert_opts([:provider, :provider_id])
  )

Repo.insert!(
  build(:identity, %{
    user_id: erich.id,
    provider: erich.provider,
    provider_id: erich.provider_id,
    provider_email: erich.email,
    provider_login: erich.handle,
    provider_name: erich.name
  }),
  Seeds.upsert_opts([:provider, :user_id])
)

richard =
  Repo.insert!(
    build(:user, %{
      email: "richard@example.com",
      name: "Richard Hendricks",
      handle: "richard",
      bio: "CEO of Pied Piper. Creator of the middle-out compression algorithm.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/richard.jpg",
      tech_stack: ["Python", "C++"]
    }),
    Seeds.upsert_opts([:email])
  )

dinesh =
  Repo.insert!(
    build(:user, %{
      email: "dinesh@example.com",
      name: "Dinesh Chugtai",
      handle: "dinesh",
      bio: "Lead Frontend Engineer at Pied Piper. Java bad, Python good.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/dinesh.png",
      tech_stack: ["Python", "JavaScript"]
    }),
    Seeds.upsert_opts([:email])
  )

gilfoyle =
  Repo.insert!(
    build(:user, %{
      email: "gilfoyle@example.com",
      name: "Bertram Gilfoyle",
      handle: "gilfoyle",
      bio: "Systems Architect. Security. DevOps. Satanist.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/gilfoyle.jpg",
      tech_stack: ["Python", "DevOps", "Security", "Linux"]
    }),
    Seeds.upsert_opts([:email])
  )

jared =
  Repo.insert!(
    build(:user, %{
      email: "jared@example.com",
      name: "Jared Dunn",
      handle: "jared",
      bio: "COO of Pied Piper. Former Hooli executive. Excel wizard.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/jared.png",
      tech_stack: ["Excel", "Project Management"]
    }),
    Seeds.upsert_opts([:email])
  )

carver =
  Repo.insert!(
    build(:user, %{
      email: "carver@example.com",
      name: "Kevin 'The Carver'",
      handle: "carver",
      bio:
        "Cloud architecture specialist. If your infrastructure needs a teardown, I'm your guy. Known for my 'insane' cloud architectures and occasional server incidents.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/carver.jpg",
      tech_stack: ["Python", "AWS", "Cloud Architecture", "DevOps", "System Architecture"]
    }),
    Seeds.upsert_opts([:email])
  )

pied_piper =
  Repo.insert!(
    build(:organization),
    Seeds.upsert_opts([:email])
  )

for user <- [erich, richard, dinesh, gilfoyle, jared] do
  Repo.insert!(
    build(:member, %{user_id: user.id, org_id: pied_piper.id}),
    Seeds.upsert_opts([:user_id, :org_id])
  )
end

if customer_id = Algora.config([:stripe, :test_customer_id]) do
  {:ok, cus} = Stripe.Customer.retrieve(customer_id)
  {:ok, pm} = Stripe.PaymentMethod.retrieve(cus.invoice_settings.default_payment_method)

  customer =
    Repo.insert!(
      build(:customer, %{
        provider_id: cus.id,
        provider_meta: Util.normalize_struct(cus),
        name: cus.name,
        user_id: pied_piper.id
      }),
      Seeds.upsert_opts([:provider, :provider_id])
    )

  _payment_method =
    Repo.insert!(
      build(:payment_method, %{
        provider_id: pm.id,
        provider_meta: Util.normalize_struct(pm),
        provider_customer_id: cus.id,
        customer_id: customer.id
      }),
      Seeds.upsert_opts([:provider, :provider_id])
    )
end

if account_id = Algora.config([:stripe, :test_account_id]) do
  {:ok, acct} = Stripe.Account.retrieve(account_id)

  Repo.insert!(
    build(:account, %{
      provider_id: acct.id,
      provider_meta: Util.normalize_struct(acct),
      name: acct.business_profile.name,
      details_submitted: acct.details_submitted,
      charges_enabled: acct.charges_enabled,
      country: acct.country,
      type: String.to_atom(acct.type),
      user_id: carver.id
    }),
    Seeds.upsert_opts([:provider, :provider_id])
  )
end

num_cycles = 20

# Create the initial contract
initial_contract =
  Repo.insert!(
    build(:contract, %{
      contractor_id: carver.id,
      client_id: pied_piper.id,
      start_date: days_from_now(-num_cycles * 7),
      end_date: days_from_now(-(num_cycles - 1) * 7)
    })
  )

# Prepay the initial contract
{:ok, _initial_prepayment} = Algora.Contracts.prepay(initial_contract)

# Iterate over the cycles to create timesheets and release & renew contracts
Enum.reduce_while(1..num_cycles, initial_contract, fn sequence_number, contract ->
  timesheet =
    Repo.insert!(
      build(:timesheet, %{
        contract_id: contract.id,
        hours_worked: Enum.random(35..45),
        inserted_at: days_from_now(-((num_cycles - sequence_number + 1) * 7) + 7)
      })
    )

  {:ok, _invoice, new_contract} = Algora.Contracts.release_and_renew(timesheet)

  {:cont, new_contract}
end)

thread =
  Repo.insert!(
    build(:thread, %{
      title: "#{pied_piper.name} x #{carver.name}"
    })
  )

for user <- [pied_piper, carver, erich, richard, dinesh, gilfoyle] do
  Repo.insert!(
    build(:participant, %{
      thread_id: thread.id,
      user_id: user.id
    })
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
  {dinesh, "adequate? the servers catch fire every time we deploy",
   days_from_now(-3, ~T[15:12:00.000000])},
  {jared,
   "our uptime metrics have been concerning. i've prepared a spreadsheet tracking all incidents",
   days_from_now(-2, ~T[10:30:00.000000])},
  {carver,
   "i specialize in unconventional but effective solutions. fair warning - my methods might seem chaotic at first",
   days_from_now(-1, ~T[11:45:00.000000])},
  {gilfoyle, "chaos is good. keeps everyone on their toes",
   days_from_now(-1, ~T[16:20:00.000000])},
  {carver, "give me root access and a week. i'll make your infrastructure bulletproof 🚀",
   days_from_now(0, ~T[09:00:00.000000])}
]

for {sender, content, inserted_at} <- messages do
  Repo.insert!(
    build(:message, %{
      thread_id: thread.id,
      sender_id: sender.id,
      content: content,
      inserted_at: inserted_at
    })
  )
end

Logger.info(
  "Contract: #{AlgoraWeb.Endpoint.url()}/org/#{pied_piper.handle}/contracts/#{initial_contract.id}"
)
