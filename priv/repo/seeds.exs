# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs <your-github-id>

alias Algora.Repo
alias Algora.Users.{User, Identity}
alias Algora.Contracts.{Contract, Timesheet}
alias Algora.Chat.{Thread, Message, Participant}
alias Algora.Payments.Transaction
alias Algora.Organizations.Member

defmodule Seeds do
  def upsert_opts(conflict_target) do
    [
      on_conflict: {:replace_all_except, [:id]},
      conflict_target: conflict_target,
      returning: true
    ]
  end

  def to_datetime(days_offset) do
    DateTime.new!(
      Date.add(Date.utc_today(), days_offset),
      ~T[00:00:00.000000],
      "Etc/UTC"
    )
  end
end

github_id =
  case System.argv() do
    [github_id] -> github_id
    _ -> "123456789"
  end

user =
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
      featured: true,
      fee_pct: 19,
      activated: true,
      website_url: "https://aviato.com",
      twitter_url: "https://twitter.com/erich",
      github_url: "https://github.com/erich",
      linkedin_url: "https://linkedin.com/in/erich",
      provider: "github",
      provider_id: github_id
    },
    Seeds.upsert_opts([:provider, :provider_id])
  )

_identity =
  Repo.insert!(
    %Identity{
      id: Nanoid.generate(),
      user_id: user.id,
      provider: user.provider,
      provider_id: user.provider_id,
      provider_token: "",
      provider_email: user.email,
      provider_login: user.handle,
      provider_name: user.name
    },
    Seeds.upsert_opts([:provider, :user_id])
  )

org =
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
      tech_stack: ["C", "Java", "Python"],
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

_member =
  Repo.insert!(
    %Member{
      id: Nanoid.generate(),
      user_id: user.id,
      org_id: org.id,
      role: :admin
    },
    Seeds.upsert_opts([:user_id, :org_id])
  )

hourly_rate = Decimal.new("75.00")
hours_per_week = 40
amount = Decimal.mult(hourly_rate, Decimal.new(hours_per_week))

original_contract_id = Nanoid.generate()

contractor =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "thecarver@example.com",
      name: "Kevin 'The Carver'",
      handle: "thecarver",
      bio:
        "Cloud architecture specialist. If your infrastructure needs a teardown, I'm your guy. Known for my 'insane' cloud architectures and occasional server incidents.",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/thecarver.jpg",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["Python", "AWS", "Cloud Architecture", "DevOps", "System Architecture"],
      featured: true,
      fee_pct: 19,
      activated: true,
      website_url: "https://kevinthecarver.dev",
      twitter_url: "https://twitter.com/thecarver",
      github_url: "https://github.com/thecarver",
      linkedin_url: "https://linkedin.com/in/thecarver"
    },
    Seeds.upsert_opts([:email])
  )

contract1 =
  Repo.insert!(%Contract{
    id: original_contract_id,
    provider_id: contractor.id,
    client_id: org.id,
    status: :completed,
    hourly_rate: hourly_rate,
    hours_per_week: hours_per_week,
    start_date: Seeds.to_datetime(-21),
    end_date: Seeds.to_datetime(-14),
    total_paid: Decimal.new("0"),
    sequence_number: 1,
    original_contract_id: original_contract_id
  })

contract2 =
  Repo.insert!(%Contract{
    id: Nanoid.generate(),
    provider_id: contractor.id,
    client_id: org.id,
    status: :completed,
    hourly_rate: hourly_rate,
    hours_per_week: hours_per_week,
    start_date: Seeds.to_datetime(-14),
    end_date: Seeds.to_datetime(-7),
    total_paid: Decimal.new("0"),
    sequence_number: 2,
    original_contract_id: original_contract_id
  })

contract3 =
  Repo.insert!(%Contract{
    id: Nanoid.generate(),
    provider_id: contractor.id,
    client_id: org.id,
    status: :active,
    hourly_rate: hourly_rate,
    hours_per_week: hours_per_week,
    start_date: Seeds.to_datetime(-7),
    end_date: Seeds.to_datetime(0),
    total_paid: Decimal.new("0"),
    sequence_number: 3,
    original_contract_id: original_contract_id
  })

timesheet1 =
  Repo.insert!(%Timesheet{
    id: Nanoid.generate(),
    contract_id: contract1.id,
    hours_worked: hours_per_week,
    start_date: Seeds.to_datetime(-21),
    end_date: Seeds.to_datetime(-14)
  })

timesheet2 =
  Repo.insert!(%Timesheet{
    id: Nanoid.generate(),
    contract_id: contract2.id,
    hours_worked: hours_per_week,
    start_date: Seeds.to_datetime(-14),
    end_date: Seeds.to_datetime(-7)
  })

timesheet3 =
  Repo.insert!(%Timesheet{
    id: Nanoid.generate(),
    contract_id: contract3.id,
    hours_worked: hours_per_week,
    start_date: Seeds.to_datetime(-7),
    end_date: Seeds.to_datetime(0)
  })

charge1 =
  Repo.insert!(%Transaction{
    id: Nanoid.generate(),
    contract_id: contract1.id,
    original_contract_id: original_contract_id,
    amount: amount,
    currency: "USD",
    type: :charge,
    status: :succeeded
  })

charge2 =
  Repo.insert!(%Transaction{
    id: Nanoid.generate(),
    contract_id: contract2.id,
    original_contract_id: original_contract_id,
    amount: amount,
    currency: "USD",
    type: :charge,
    status: :succeeded
  })

charge3 =
  Repo.insert!(%Transaction{
    id: Nanoid.generate(),
    contract_id: contract3.id,
    original_contract_id: original_contract_id,
    amount: amount,
    currency: "USD",
    type: :charge,
    status: :succeeded
  })

transfer1 =
  Repo.insert!(%Transaction{
    id: Nanoid.generate(),
    contract_id: contract1.id,
    original_contract_id: original_contract_id,
    timesheet_id: timesheet1.id,
    amount: amount,
    currency: "USD",
    type: :transfer,
    status: :succeeded
  })

transfer2 =
  Repo.insert!(%Transaction{
    id: Nanoid.generate(),
    contract_id: contract2.id,
    original_contract_id: original_contract_id,
    timesheet_id: timesheet2.id,
    amount: amount,
    currency: "USD",
    type: :transfer,
    status: :succeeded
  })

# Create direct chat thread
thread =
  Repo.insert!(%Thread{
    id: Nanoid.generate(),
    title: "#{org.name} x #{contractor.name}"
  })

# Add thread participants
for participant_user <- [org, contractor] do
  Repo.insert!(%Participant{
    id: Nanoid.generate(),
    thread_id: thread.id,
    user_id: participant_user.id,
    last_read_at: DateTime.utc_now()
  })
end

# Seed messages
messages = [
  {user.id,
   "hey kevin, i heard you're the best cloud architect in the valley. we need someone to help scale pied piper's infrastructure"},
  {contractor.id,
   "thanks for reaching out! i've been following pied piper's middle-out compression algorithm - really cool stuff"},
  {user.id,
   "our current setup is basically just a bunch of aws instances held together with duct tape and prayers lol"},
  {contractor.id,
   "classic startup architecture. i specialize in tearing down and rebuilding scalable cloud infrastructure. when do you need this done?"},
  {user.id, "asap. our user base is growing exponentially and the servers are already sweating"},
  {contractor.id,
   "i can start next week. fair warning though - my methods are a bit... unconventional. but they work"},
  {user.id,
   "as long as you can handle the traffic spikes, i don't care if you have to sacrifice a goat to the aws gods"},
  {contractor.id,
   "no goats needed, but i'll need root access and a lot of coffee. let's do this 🚀"}
]

for {sender_id, content} <- messages do
  Repo.insert!(%Message{
    id: Nanoid.generate(),
    thread_id: thread.id,
    sender_id: sender_id,
    content: content
  })
end
