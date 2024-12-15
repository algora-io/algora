defmodule Algora.Factory do
  alias Algora.Repo

  def build(:identity) do
    %Algora.Users.Identity{
      id: Nanoid.generate(),
      provider: "github",
      provider_token: ""
    }
  end

  def build(:user) do
    %Algora.Users.User{
      id: Nanoid.generate(),
      type: :individual,
      email: "erich@example.com",
      display_name: "Erlich Bachman",
      handle: "erich",
      bio: "Founder of Aviato, Incubator extraordinaire",
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/erich.jpg",
      location: "Palo Alto, CA",
      country: "US",
      timezone: "America/Los_Angeles",
      tech_stack: ["HTML"],
      hourly_rate_min: Money.new!(100, :USD),
      hourly_rate_max: Money.new!(150, :USD),
      hours_per_week: 40,
      website_url: "https://aviato.com",
      twitter_url: "https://twitter.com/erich",
      github_url: "https://github.com/erich",
      linkedin_url: "https://linkedin.com/in/erich",
      provider: "github"
    }
  end

  def build(:organization) do
    %Algora.Users.User{
      id: Nanoid.generate(),
      type: :organization,
      email: "piedpiper@example.com",
      display_name: "Pied Piper",
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
      hourly_rate_min: Money.new!(100, :USD),
      hourly_rate_max: Money.new!(150, :USD),
      hours_per_week: 40,
      featured: true,
      fee_pct: 19,
      activated: true,
      website_url: "https://piedpiper.com",
      twitter_url: "https://twitter.com/piedpiper",
      github_url: "https://github.com/piedpiper",
      discord_url: "https://discord.gg/piedpiper",
      slack_url: "https://piedpiper.slack.com"
    }
  end

  def build(:member) do
    %Algora.Organizations.Member{
      id: Nanoid.generate(),
      role: :admin
    }
  end

  def build(:customer) do
    %Algora.Payments.Customer{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: "cus_1234567890",
      provider_meta: %{},
      name: "Pied Piper",
      region: :US
    }
  end

  def build(:payment_method) do
    %Algora.Payments.PaymentMethod{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: "pm_1234567890",
      provider_customer_id: "cus_1234567890"
    }
  end

  def build(:account) do
    %Algora.Payments.Account{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: "acct_1234567890",
      name: "Kevin 'The Carver'",
      details_submitted: true,
      charges_enabled: true,
      service_agreement: "recipient",
      country: "US",
      type: :express,
      region: :US,
      stale: false
    }
  end

  def build(:contract) do
    id = Nanoid.generate()

    %Algora.Contracts.Contract{
      id: id,
      original_contract_id: id,
      status: :active,
      hourly_rate: Money.new!(75, :USD),
      hours_per_week: 40,
      sequence_number: 1,
      start_date: days_from_now(0),
      end_date: days_from_now(7)
    }
  end

  def build(:transaction) do
    %Algora.Payments.Transaction{
      id: Nanoid.generate()
    }
  end

  def build(:timesheet) do
    %Algora.Contracts.Timesheet{
      id: Nanoid.generate(),
      hours_worked: 40
    }
  end

  def build(:thread) do
    %Algora.Chat.Thread{
      id: Nanoid.generate(),
      title: "Lorem ipsum dolor sit amet"
    }
  end

  def build(:participant) do
    %Algora.Chat.Participant{
      id: Nanoid.generate(),
      last_read_at: DateTime.utc_now()
    }
  end

  def build(:message) do
    %Algora.Chat.Message{
      id: Nanoid.generate(),
      content: "What's up?"
    }
  end

  def build(:repository) do
    %Algora.Workspace.Repository{
      id: Nanoid.generate(),
      provider: "github",
      provider_id: "#{:rand.uniform(999_999_999)}",
      name: "middle-out",
      url: "https://github.com/piedpiper/middle-out",
      provider_meta: %{}
    }
  end

  def build(:ticket) do
    %Algora.Workspace.Ticket{
      id: Nanoid.generate(),
      provider: "github",
      provider_id: "#{:rand.uniform(999_999_999)}",
      type: :issue,
      title: "Optimize compression algorithm for large files",
      description: "We need to improve performance when handling files over 1GB",
      number: :rand.uniform(100),
      url: "https://github.com/piedpiper/middle-out/issues/1",
      provider_meta: %{}
    }
  end

  def build(:bounty) do
    %Algora.Bounties.Bounty{
      id: Nanoid.generate()
    }
  end

  def build(:claim) do
    %Algora.Bounties.Claim{
      id: Nanoid.generate(),
      provider: "github",
      provider_id: "#{:rand.uniform(999_999_999)}",
      type: :code,
      status: :pending,
      title: "Implemented compression optimization",
      description: "Added parallel processing for large files",
      url: "https://github.com/piedpiper/middle-out/pull/2",
      provider_meta: %{}
    }
  end

  def build(:review) do
    %Algora.Reviews.Review{
      id: Nanoid.generate(),
      rating: Algora.Reviews.Review.max_rating(),
      content:
        "Great developer who writes clean code, communicates well, and always delivers on time!"
    }
  end

  # Convenience API
  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> Repo.insert!()
  end

  def upsert!(factory_name, conflict_target, attributes \\ []) do
    factory_name
    |> build(attributes)
    |> Repo.insert!(
      on_conflict: {:replace_all_except, [:id, :name]},
      conflict_target: conflict_target,
      returning: true
    )
  end

  def days_from_now(days_offset, time \\ ~T[00:00:00.000000]) do
    DateTime.new!(
      Date.add(Date.utc_today(), days_offset),
      time,
      "Etc/UTC"
    )
  end
end
