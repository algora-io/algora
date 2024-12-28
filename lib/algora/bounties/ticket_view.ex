defmodule Algora.Bounties.TicketView do
  use Algora.Schema
  import Ecto.Query
  alias Algora.Repo

  @primary_key false
  schema "ticket_views" do
    # Denormalized fields from Ticket
    field :title, :string
    field :number, :integer
    field :url, :string

    # Computed/aggregated fields
    field :total_bounty_amount, Money.Ecto.Composite.Type
    field :bounty_count, :integer

    # Original associations
    belongs_to :ticket, Algora.Workspace.Ticket
    belongs_to :repository, Algora.Workspace.Repository
    has_many :bounties, Algora.Bounties.Bounty, references: :ticket_id

    has_many :top_bounties, Algora.Bounties.Bounty, references: :ticket_id
  end

  def base_query(criteria \\ []) do
    bounty_subquery =
      from(b in Algora.Bounties.Bounty)
      |> apply_criteria(criteria)
      |> group_by([b], b.ticket_id)
      |> select([b], %{
        ticket_id: b.ticket_id,
        total_bounty_amount: sum(b.amount),
        bounty_count: count(b.id)
      })

    from(t in Algora.Workspace.Ticket)
    |> join(:inner, [t], b in subquery(bounty_subquery), on: b.ticket_id == t.id, as: :b)
    |> join(:left, [t], r in assoc(t, :repository), as: :r)
    |> join(:left, [t, r: repo], ro in assoc(repo, :user), as: :ro)
    |> select([t, b: b, r: r, ro: ro], %__MODULE__{
      ticket_id: t.id,
      title: t.title,
      number: t.number,
      url: t.url,
      repository: %{
        id: r.id,
        name: r.name,
        owner: %{
          login: ro.provider_login
        }
      },
      total_bounty_amount: b.total_bounty_amount,
      bounty_count: b.bounty_count
    })
    |> order_by([t, b: b],
      desc: b.total_bounty_amount,
      desc: b.bounty_count,
      desc: t.inserted_at
    )
  end

  def list(criteria \\ []) do
    tickets = base_query(criteria) |> Repo.all()
    ticket_ids = Enum.map(tickets, & &1.ticket_id)

    top_bounties = fetch_top_bounties(ticket_ids)

    tickets
    |> Enum.map(fn ticket ->
      Map.put(ticket, :top_bounties, Map.get(top_bounties, ticket.ticket_id, []))
    end)
  end

  defp fetch_top_bounties(ticket_ids) do
    from(b in Algora.Bounties.Bounty)
    |> join(:left, [b], o in assoc(b, :owner))
    |> where([b], b.ticket_id in ^ticket_ids)
    |> select([b, o], %{
      ticket_id: b.ticket_id,
      amount: b.amount,
      owner: %{
        id: o.id,
        handle: o.handle,
        avatar_url: o.avatar_url,
        provider_login: o.provider_login
      }
    })
    |> order_by([b], [b.ticket_id, desc: b.amount])
    |> Repo.all()
    |> Enum.group_by(& &1.ticket_id)
    |> Map.new(fn {ticket_id, bounties} ->
      {ticket_id, Enum.take(bounties, 5)}
    end)
  end

  @type criteria :: %{
          optional(:limit) => non_neg_integer(),
          optional(:owner_id) => integer(),
          optional(:status) => :open | :paid,
          optional(:tech_stack) => [String.t()]
        }
  defp apply_criteria(query, criteria) do
    Enum.reduce(criteria, query, fn
      {:limit, limit}, query ->
        from([b] in query, limit: ^limit)

      {:owner_id, owner_id}, query ->
        from([b] in query, where: b.owner_id == ^owner_id)

      {:status, status}, query ->
        from([b] in query, where: b.status == ^status)

      _, query ->
        query
    end)
  end

  # TODO: remove this once we have real data
  def sample_tickets do
    [
      %{
        id: "https://github.com/tuist/tuist/issues/6456",
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
        id: "https://github.com/tuist/tuist/issues/6048",
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
        id: "https://github.com/tuist/tuist/issues/5920",
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
        id: "https://github.com/Cap-go/capacitor-updater/issues/411",
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
        id: "https://github.com/tuist/tuist/issues/268",
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
        id: "https://github.com/tuist/tuist/issues/5912",
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
        id: "https://github.com/tuist/tuist/issues/5925",
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
        id: "https://github.com/tuist/tuist/issues/5552",
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
        id: "https://github.com/Cap-go/capgo/issues/229",
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
