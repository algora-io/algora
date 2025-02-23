defmodule Algora.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: Algora.Repo

  alias Algora.Accounts.User
  alias Algora.Reviews.Review
  alias Algora.Workspace.Installation

  def identity_factory do
    %Algora.Accounts.Identity{
      id: Nanoid.generate(),
      provider: "github",
      provider_id: sequence(:provider_id, &"#{&1 + offset(:identity)}"),
      provider_token: sequence(:provider_token, &"token#{&1}"),
      provider_email: sequence(:provider_email, &"identity#{&1}@example.com"),
      provider_login: sequence(:provider_login, &"identity#{&1}")
    }
  end

  def user_factory do
    %User{
      id: Nanoid.generate(),
      type: :individual,
      email: sequence(:email, &"erlich#{&1}@example.com"),
      display_name: "Erlich Bachman",
      handle: sequence(:handle, &"erlich#{&1}"),
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
      provider: "github",
      provider_id: sequence(:provider_id, &"#{&1 + offset(:user)}"),
      provider_login: sequence(:provider_login, &"erlich#{&1}")
    }
  end

  def organization_factory do
    %User{
      id: Nanoid.generate(),
      type: :organization,
      email: sequence(:email, &"piedpiper#{&1}@example.com"),
      display_name: "Pied Piper",
      handle: sequence(:handle, &"piedpiper#{&1}"),
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
      slack_url: "https://piedpiper.slack.com",
      provider: "github",
      provider_login: "piedpiper",
      provider_id: sequence(:provider_id, &"#{&1 + offset(:organization)}")
    }
  end

  def member_factory do
    %Algora.Organizations.Member{
      id: Nanoid.generate(),
      role: :admin
    }
  end

  def customer_factory do
    %Algora.Payments.Customer{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: sequence(:cus, &"cus_#{&1}"),
      provider_meta: %{},
      name: "Pied Piper"
    }
  end

  def payment_method_factory do
    %Algora.Payments.PaymentMethod{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: sequence(:pm, &"pm_#{&1}"),
      provider_customer_id: sequence(:cus, &"cus_#{&1}")
    }
  end

  def account_factory do
    %Algora.Payments.Account{
      id: Nanoid.generate(),
      provider: "stripe",
      provider_id: sequence(:acct, &"acct_#{&1}"),
      provider_meta: %{},
      name: "Kevin 'The Carver'",
      details_submitted: true,
      charges_enabled: true,
      payouts_enabled: true,
      service_agreement: "recipient",
      country: "US",
      type: :express,
      stale: false
    }
  end

  def contract_factory do
    id = Nanoid.generate()

    %Algora.Contracts.Contract{
      id: id,
      original_contract_id: id,
      status: :active,
      hourly_rate_min: Money.new!(125, :USD),
      hourly_rate_max: Money.new!(175, :USD),
      hourly_rate: Money.new!(150, :USD),
      hours_per_week: 40,
      sequence_number: 1,
      start_date: days_from_now(0),
      end_date: days_from_now(7),
      activities: []
    }
  end

  def transaction_factory do
    %Algora.Payments.Transaction{
      id: Nanoid.generate(),
      group_id: Nanoid.generate()
    }
  end

  def timesheet_factory do
    %Algora.Contracts.Timesheet{
      id: Nanoid.generate(),
      hours_worked: 40
    }
  end

  def thread_factory do
    %Algora.Chat.Thread{
      id: Nanoid.generate(),
      title: "Lorem ipsum dolor sit amet"
    }
  end

  def participant_factory do
    %Algora.Chat.Participant{
      id: Nanoid.generate(),
      last_read_at: DateTime.utc_now()
    }
  end

  def message_factory do
    %Algora.Chat.Message{
      id: Nanoid.generate(),
      content: "What's up?"
    }
  end

  def repository_factory do
    %Algora.Workspace.Repository{
      id: Nanoid.generate(),
      provider: "github",
      provider_id: sequence(:provider_id, &"#{&1 + offset(:repository)}"),
      name: "middle-out",
      url: "https://github.com/piedpiper/middle-out",
      og_image_url: "https://algora.io/asset/storage/v1/object/public/mock/piedpiper-banner.jpg",
      provider_meta: %{}
    }
  end

  def ticket_factory do
    %Algora.Workspace.Ticket{
      id: Nanoid.generate(),
      provider: "github",
      provider_id: sequence(:provider_id, &"#{&1 + offset(:ticket)}"),
      type: :issue,
      title: "Optimize compression algorithm for large files",
      description: "We need to improve performance when handling files over 1GB",
      number: sequence(:number, &"#{&1}"),
      url: sequence(:url, &"https://github.com/piedpiper/middle-out/issues/#{&1}"),
      provider_meta: %{}
    }
  end

  def bounty_factory do
    %Algora.Bounties.Bounty{
      id: Nanoid.generate()
    }
  end

  def claim_factory do
    id = Nanoid.generate()

    %Algora.Bounties.Claim{
      id: id,
      group_id: id,
      type: :pull_request,
      status: :pending,
      url: sequence(:url, &"https://github.com/piedpiper/middle-out/pull/#{&1}")
    }
  end

  def review_factory do
    %Review{
      id: Nanoid.generate(),
      rating: Review.max_rating(),
      content: "Great developer who writes clean code, communicates well, and always delivers on time!"
    }
  end

  def installation_factory do
    %Installation{
      id: Nanoid.generate(),
      provider: "github",
      provider_id: sequence(:provider_id, &"#{&1 + offset(:installation)}"),
      provider_user_id: sequence(:provider_user_id, &"#{&1 + offset(:installation)}"),
      provider_meta: %{
        "account" => %{"avatar_url" => "https://algora.io/asset/storage/v1/object/public/mock/piedpiper-logo.png"},
        "repository_selection" => "selected"
      },
      avatar_url: "https://algora.io/asset/storage/v1/object/public/mock/piedpiper-logo.png",
      repository_selection: "selected"
    }
  end

  # Convenience API
  def insert!(factory_name, attributes \\ []) do
    insert(factory_name, attributes)
  end

  def upsert!(factory_name, conflict_target, attributes \\ []) do
    insert(
      factory_name,
      attributes,
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

  defp offset(factory_name) do
    # Convert each character to its ASCII value, multiply by position to ensure
    # different orderings of same letters produce different results
    factory_name
    |> Atom.to_string()
    |> String.to_charlist()
    |> Enum.with_index(1)
    |> Enum.reduce(0, fn {char, index}, acc -> acc + char * index end)
    |> Kernel.*(1_000_000)
  end
end
