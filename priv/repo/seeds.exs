# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs <your-github-id>

require Logger
alias Algora.{Repo, Util}
alias Algora.Users.{User, Identity}
alias Algora.Contracts.{Contract, Timesheet}
alias Algora.Chat.{Thread, Message, Participant}
alias Algora.Payments.{Transaction, Customer, PaymentMethod, Account}
alias Algora.Organizations.Member

defmodule Seeds do
  def upsert_opts(conflict_target) do
    [
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: conflict_target,
      returning: true
    ]
  end

  def to_datetime(days_offset, time \\ ~T[00:00:00.000000]) do
    DateTime.new!(
      Date.add(Date.utc_today(), days_offset),
      time,
      "Etc/UTC"
    )
  end

  def calculate_charge_amount(previous_timesheet, hours_per_week, hourly_rate) do
    case previous_timesheet do
      nil ->
        # First period - charge full amount
        Money.mult!(hourly_rate, hours_per_week)

      timesheet ->
        # Subsequent periods - adjust based on previous usage
        # Need to charge enough to have hours_per_week available after accounting for previous over/under usage
        previous_charged = hours_per_week
        previous_used = timesheet.hours_worked
        hours_to_charge = hours_per_week - (previous_charged - previous_used)
        Money.mult!(hourly_rate, hours_to_charge)
    end
  end

  def create_contract_cycle(params) do
    %{
      contractor_id: contractor_id,
      client_id: client_id,
      hourly_rate: hourly_rate,
      hours_per_week: hours_per_week,
      start_date: start_date,
      end_date: end_date,
      sequence_number: sequence_number,
      original_contract_id: original_contract_id,
      previous_timesheet: previous_timesheet,
      hours_worked: hours_worked,
      status: status
    } = params

    total_fee = Money.zero(:USD)
    net_amount = calculate_charge_amount(previous_timesheet, hours_per_week, hourly_rate)
    gross_amount = Money.add!(net_amount, total_fee)

    contract =
      Repo.insert!(%Contract{
        id: if(sequence_number == 1, do: original_contract_id, else: Nanoid.generate()),
        contractor_id: contractor_id,
        client_id: client_id,
        status: status,
        hourly_rate: hourly_rate,
        hours_per_week: hours_per_week,
        start_date: start_date,
        end_date: end_date,
        total_paid: Money.zero(:USD),
        sequence_number: sequence_number,
        original_contract_id: original_contract_id,
        inserted_at:
          Seeds.to_datetime(
            start_date.day,
            Time.new!(Enum.random(9..16), Enum.random(0..59), Enum.random(0..59), 0)
          )
      })

    _charge =
      Repo.insert!(%Transaction{
        id: Nanoid.generate(),
        contract_id: contract.id,
        original_contract_id: original_contract_id,
        gross_amount: gross_amount,
        net_amount: net_amount,
        total_fee: total_fee,
        type: :charge,
        status: :succeeded,
        inserted_at:
          Seeds.to_datetime(
            start_date.day,
            Time.new!(Enum.random(17..20), Enum.random(0..59), Enum.random(0..59), 0)
          )
      })

    timesheet =
      Repo.insert!(%Timesheet{
        id: Nanoid.generate(),
        contract_id: contract.id,
        hours_worked: hours_worked,
        start_date: start_date,
        end_date: end_date,
        inserted_at:
          Seeds.to_datetime(
            end_date.day,
            Time.new!(Enum.random(15..19), Enum.random(0..59), Enum.random(0..59), 0)
          )
      })

    if status == :completed do
      _transfer =
        Repo.insert!(%Transaction{
          id: Nanoid.generate(),
          contract_id: contract.id,
          original_contract_id: original_contract_id,
          timesheet_id: timesheet.id,
          gross_amount: net_amount,
          net_amount: net_amount,
          total_fee: Money.zero(:USD),
          type: :transfer,
          status: :succeeded,
          inserted_at:
            Seeds.to_datetime(
              end_date.day,
              Time.new!(Enum.random(19..23), Enum.random(0..59), Enum.random(0..59), 0)
            )
        })
    end

    {contract, timesheet}
  end
end

github_id =
  case System.argv() do
    [github_id] -> github_id
    _ -> "123456789"
  end

erich =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "erich@example.com",
      name: "Erlich Bachman",
      handle: "erich",
      bio: "Founder of Aviato, Incubator extraordinaire",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/erich.jpg",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["HTML"],
      website_url: "https://aviato.com",
      twitter_url: "https://twitter.com/erich",
      github_url: "https://github.com/erich",
      linkedin_url: "https://linkedin.com/in/erich",
      provider: "github",
      provider_id: github_id
    },
    Seeds.upsert_opts([:provider, :provider_id])
  )

Repo.insert!(
  %Identity{
    id: Nanoid.generate(),
    user_id: erich.id,
    provider: erich.provider,
    provider_id: erich.provider_id,
    provider_token: "",
    provider_email: erich.email,
    provider_login: erich.handle,
    provider_name: erich.name
  },
  Seeds.upsert_opts([:provider, :user_id])
)

richard =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "richard@example.com",
      name: "Richard Hendricks",
      handle: "richard",
      bio: "CEO of Pied Piper. Creator of the middle-out compression algorithm.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/richard.jpg",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["Python", "C++", "Algorithms"],
      github_url: "https://github.com/richard"
    },
    Seeds.upsert_opts([:email])
  )

dinesh =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "dinesh@example.com",
      name: "Dinesh Chugtai",
      handle: "dinesh",
      bio: "Lead Frontend Engineer at Pied Piper. Java bad, Python good.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/dinesh.png",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["Python", "JavaScript", "Frontend"],
      github_url: "https://github.com/dinesh"
    },
    Seeds.upsert_opts([:email])
  )

gilfoyle =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "gilfoyle@example.com",
      name: "Bertram Gilfoyle",
      handle: "gilfoyle",
      bio: "Systems Architect. Security. DevOps. Satanist.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/gilfoyle.jpg",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["Python", "DevOps", "Security", "Linux"],
      github_url: "https://github.com/gilfoyle"
    },
    Seeds.upsert_opts([:email])
  )

jared =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "jared@example.com",
      name: "Jared Dunn",
      handle: "jared",
      bio: "COO of Pied Piper. Former Hooli executive. Excel wizard.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/jared.png",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["Excel", "Project Management"],
      github_url: "https://github.com/jared"
    },
    Seeds.upsert_opts([:email])
  )

carver =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "carver@example.com",
      name: "Kevin 'The Carver'",
      handle: "carver",
      bio:
        "Cloud architecture specialist. If your infrastructure needs a teardown, I'm your guy. Known for my 'insane' cloud architectures and occasional server incidents.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/carver.jpg",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["Python", "AWS", "Cloud Architecture", "DevOps", "System Architecture"],
      website_url: "https://kevinthecarver.dev",
      twitter_url: "https://twitter.com/carver",
      github_url: "https://github.com/carver",
      linkedin_url: "https://linkedin.com/in/carver"
    },
    Seeds.upsert_opts([:email])
  )

pied_piper =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :organization,
      email: "piedpiper@example.com",
      name: "Pied Piper",
      handle: "piedpiper",
      bio:
        "Making the world a better place through constructing elegant hierarchies for maximum code re-use and extensibility",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/piedpiper-logo.png",
      og_title: "Pied Piper | Middle-Out Compression Platform",
      og_image_url: "https://algora.io/asset/storage/v1/object/public/mock/piedpiper-banner.jpg",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      stargazers_count: 2481,
      domain: "piedpiper.com",
      tech_stack: ["C++", "Java", "Python", "JavaScript"],
      featured: true,
      fee_pct: 19,
      activated: true,
      website_url: "https://piedpiper.com",
      twitter_url: "https://twitter.com/piedpiper",
      github_url: "https://github.com/piedpiper",
      discord_url: "https://discord.gg/piedpiper",
      slack_url: "https://piedpiper.slack.com"
    },
    Seeds.upsert_opts([:email])
  )

for user <- [erich, richard, dinesh, gilfoyle, jared] do
  Repo.insert!(
    %Member{
      id: Nanoid.generate(),
      user_id: user.id,
      org_id: pied_piper.id,
      role: :admin
    },
    Seeds.upsert_opts([:user_id, :org_id])
  )
end

if customer_id = Algora.config([:stripe, :test_customer_id]) do
  {:ok, cus} = Stripe.Customer.retrieve(customer_id)
  {:ok, pm} = Stripe.PaymentMethod.retrieve(cus.invoice_settings.default_payment_method)

  customer =
    Repo.insert!(
      %Customer{
        id: Nanoid.generate(),
        provider: "stripe",
        provider_id: cus.id,
        provider_meta: Util.normalize_struct(cus),
        name: cus.name,
        region: :US,
        user_id: pied_piper.id
      },
      Seeds.upsert_opts([:provider, :provider_id])
    )

  _payment_method =
    Repo.insert!(
      %PaymentMethod{
        id: Nanoid.generate(),
        provider: "stripe",
        provider_id: pm.id,
        provider_meta: Util.normalize_struct(pm),
        provider_customer_id: cus.id,
        customer_id: customer.id
      },
      Seeds.upsert_opts([:provider, :provider_id])
    )
end

if account_id = Algora.config([:stripe, :test_account_id]) do
  {:ok, acct} = Stripe.Account.retrieve(account_id)

  Repo.insert!(
    %Account{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: acct.id,
      provider_meta: Util.normalize_struct(acct),
      name: acct.business_profile.name,
      details_submitted: acct.details_submitted,
      charges_enabled: acct.charges_enabled,
      service_agreement: "recipient",
      country: acct.country,
      type: String.to_atom(acct.type),
      region: :US,
      stale: false,
      user_id: carver.id
    },
    Seeds.upsert_opts([:provider, :provider_id])
  )
end

hourly_rate = Money.new!(75, :USD)
hours_per_week = 40
original_contract_id = Nanoid.generate()

{_contract1, timesheet1} =
  Seeds.create_contract_cycle(%{
    contractor_id: carver.id,
    client_id: pied_piper.id,
    hourly_rate: hourly_rate,
    hours_per_week: hours_per_week,
    start_date: Seeds.to_datetime(-21),
    end_date: Seeds.to_datetime(-14),
    sequence_number: 1,
    original_contract_id: original_contract_id,
    previous_timesheet: nil,
    hours_worked: 42,
    status: :completed
  })

{_contract2, timesheet2} =
  Seeds.create_contract_cycle(%{
    contractor_id: carver.id,
    client_id: pied_piper.id,
    hourly_rate: hourly_rate,
    hours_per_week: hours_per_week,
    start_date: Seeds.to_datetime(-14),
    end_date: Seeds.to_datetime(-7),
    sequence_number: 2,
    original_contract_id: original_contract_id,
    previous_timesheet: timesheet1,
    hours_worked: 35,
    status: :completed
  })

{_contract3, _timesheet3} =
  Seeds.create_contract_cycle(%{
    contractor_id: carver.id,
    client_id: pied_piper.id,
    hourly_rate: hourly_rate,
    hours_per_week: hours_per_week,
    start_date: Seeds.to_datetime(-7),
    end_date: Seeds.to_datetime(0),
    sequence_number: 3,
    original_contract_id: original_contract_id,
    previous_timesheet: timesheet2,
    hours_worked: 38,
    status: :active
  })

thread =
  Repo.insert!(%Thread{
    id: Nanoid.generate(),
    title: "#{pied_piper.name} x #{carver.name}"
  })

for user <- [pied_piper, carver, erich, richard, dinesh, gilfoyle] do
  Repo.insert!(%Participant{
    id: Nanoid.generate(),
    thread_id: thread.id,
    user_id: user.id,
    last_read_at: DateTime.utc_now()
  })
end

messages = [
  {erich,
   "hey kevin, i heard you're the best cloud architect in the valley. we need someone to help scale pied piper's infrastructure",
   Seeds.to_datetime(-4, ~T[09:15:00.000000])},
  {carver,
   "thanks for reaching out! i've been following pied piper's middle-out compression algorithm - really excited about its potential",
   Seeds.to_datetime(-4, ~T[09:45:00.000000])},
  {richard, "yeah our infrastructure needs help. we're getting crushed by the user growth",
   Seeds.to_datetime(-4, ~T[14:20:00.000000])},
  {gilfoyle, "the current setup is adequate. but i suppose a second opinion wouldn't hurt",
   Seeds.to_datetime(-3, ~T[15:05:00.000000])},
  {dinesh, "adequate? the servers catch fire every time we deploy",
   Seeds.to_datetime(-3, ~T[15:12:00.000000])},
  {jared,
   "our uptime metrics have been concerning. i've prepared a spreadsheet tracking all incidents",
   Seeds.to_datetime(-2, ~T[10:30:00.000000])},
  {carver,
   "i specialize in unconventional but effective solutions. fair warning - my methods might seem chaotic at first",
   Seeds.to_datetime(-1, ~T[11:45:00.000000])},
  {gilfoyle, "chaos is good. keeps everyone on their toes",
   Seeds.to_datetime(-1, ~T[16:20:00.000000])},
  {carver, "give me root access and a week. i'll make your infrastructure bulletproof 🚀",
   Seeds.to_datetime(0, ~T[09:00:00.000000])}
]

for {sender, content, inserted_at} <- messages do
  Repo.insert!(%Message{
    id: Nanoid.generate(),
    thread_id: thread.id,
    sender_id: sender.id,
    content: content,
    inserted_at: inserted_at
  })
end

Logger.info(
  "Contract: #{AlgoraWeb.Endpoint.url()}/org/#{pied_piper.handle}/contracts/#{original_contract_id}"
)
