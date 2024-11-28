# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs <your-github-id>

alias Algora.Repo
alias Algora.Users.{User, Identity}
alias Algora.Contracts.Contract
alias Algora.Organizations.Member

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

user =
  Repo.insert!(
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: "erich@example.com",
      name: "Erlich Bachman",
      handle: "erich",
      bio: "Founder of Aviato, Incubator extraordinaire",
      avatar_url:
        "https://static.wikia.nocookie.net/silicon-valley/images/1/1f/Erlich_Bachman.jpg",
      location: "Palo Alto, CA",
      country: "US",
      tech_stack: ["Python", "JavaScript", "Ruby"],
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
      avatar_url:
        "http://mattingly.design/articles/wp-content/uploads/2019/10/pied-piper-tshirt-logo.gif",
      og_title: "Pied Piper | Middle-Out Compression Platform",
      og_image_url:
        "https://mattingly.design/articles/wp-content/uploads/2020/07/silicon-valley-logo-story-arc.jpg",
      location: "Palo Alto, CA",
      country: "US",
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

_contract =
  Repo.insert!(%Contract{
    id: Nanoid.generate(),
    provider_id: user.id,
    client_id: org.id,
    status: :active,
    hourly_rate: Decimal.new("75.00"),
    hours_per_week: 40,
    start_date: Date.utc_today(),
    end_date: Date.add(Date.utc_today(), 7),
    total_paid: Decimal.new("0"),
    sequence_number: 1
  })
