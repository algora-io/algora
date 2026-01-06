defmodule Algora.Activities.DiscordViews do
  @moduledoc false
  alias Algora.Repo
  alias AlgoraCloud.AdminTasks.AdminTask

  def render(%{type: type} = activity) when is_binary(type) do
    render(%{activity | type: String.to_existing_atom(type)})
  end

  def render(%{type: :bounty_posted, assoc: bounty}) do
    bounty = Repo.preload(bounty, [:owner, :creator, ticket: [repository: :user]])

    %{
      embeds: [
        %{
          color: 0x6366F1,
          title: "#{bounty.amount} bounty!",
          author: %{
            name: bounty.ticket.repository.user.provider_login,
            icon_url: bounty.ticket.repository.user.avatar_url,
            url:
              "https://github.com/#{bounty.ticket.repository.user.provider_login}/#{bounty.ticket.repository.name}/issues/#{bounty.ticket.number}"
          },
          footer: %{
            text: bounty.creator.name,
            icon_url: bounty.creator.avatar_url
          },
          thumbnail: %{url: bounty.owner.avatar_url},
          fields: [
            %{
              name: "Sponsor",
              value: bounty.owner.name,
              inline: false
            },
            %{
              name: "Ticket",
              value: "#{bounty.ticket.repository.name}##{bounty.ticket.number}: #{bounty.ticket.title}",
              inline: false
            }
          ],
          url:
            "https://github.com/#{bounty.ticket.repository.user.provider_login}/#{bounty.ticket.repository.name}/issues/#{bounty.ticket.number}",
          timestamp: bounty.inserted_at
        }
      ]
    }
  end

  def render(%{type: :transaction_succeeded, assoc: tx}) do
    tx = Repo.preload(tx, [:user, linked_transaction: [:user]])

    %{
      embeds: [
        %{
          color: 0x6366F1,
          title: "#{tx.net_amount} paid!",
          author: %{
            name: tx.linked_transaction.user.name,
            icon_url: tx.linked_transaction.user.avatar_url,
            url: "#{AlgoraWeb.Endpoint.url()}/#{tx.linked_transaction.user.handle}"
          },
          footer: %{
            text: tx.user.name,
            icon_url: tx.user.avatar_url
          },
          thumbnail: %{url: tx.user.avatar_url},
          fields: [
            %{
              name: "Sender",
              value: tx.linked_transaction.user.name,
              inline: false
            },
            %{
              name: "Recipient",
              value: tx.user.name,
              inline: false
            }
          ],
          url: "#{AlgoraWeb.Endpoint.url()}/#{tx.linked_transaction.user.handle}",
          timestamp: tx.succeeded_at
        }
      ]
    }
  end

  def render(_activity), do: nil

  @doc """
  Renders a rich Discord embed for an admin task with all available information.
  """
  def render_admin_task(%AdminTask{} = task) do
    payload = task.payload || %{}
    website_metadata = Map.get(payload, "website_metadata", %{})
    company_metadata = Map.get(payload, "company_metadata", %{})
    funding = Map.get(company_metadata, "funding", %{})
    person = Map.get(company_metadata, "person", %{})
    email = Map.get(payload, "email", "Unknown")
    domain = email |> String.split("@") |> List.last()
    is_company_domain = Map.get(payload, "is_company_domain", false)

    company_name = Map.get(website_metadata, "display_name") || String.capitalize(domain)
    website_url = Map.get(website_metadata, "website_url") || "https://#{domain}"

    dbg(company_name)
    # Build fields
    fields = []

    fields =
      if hire_type = Map.get(payload, "hire_type") do
        hire_type_field = %{
          name: "Hire Type",
          value: hire_type |> String.replace("_", " ") |> String.capitalize(),
          inline: true
        }

        [hire_type_field | fields]
      else
        fields
      end

    fields =
      if comp_range = Map.get(payload, "comp_range") do
        comp_field = %{
          name: "Compensation",
          value: comp_range,
          inline: true
        }

        [comp_field | fields]
      else
        fields
      end

    fields =
      if location = Map.get(payload, "location") do
        location_field = %{
          name: "Location",
          value: location,
          inline: true
        }

        [location_field | fields]
      else
        fields
      end

    fields =
      if tech_stack = Map.get(payload, "tech_stack") do
        tech_stack_field = %{
          name: "Tech Stack",
          value: Enum.join(tech_stack, ", "),
          inline: true
        }

        [tech_stack_field | fields]
      else
        fields
      end

    # Person information fields
    fields =
      if full_name = Map.get(person, "full_name") do
        person_field = %{
          name: "Person",
          value: "#{full_name} (#{email})",
          inline: false
        }

        [person_field | fields]
      else
        fields
      end

    fields =
      if role = Map.get(person, "role") do
        role_field = %{
          name: "Role",
          value: role,
          inline: true
        }

        [role_field | fields]
      else
        fields
      end

    fields =
      if bio = Map.get(person, "bio") do
        bio_field = %{
          name: "Bio",
          value: bio,
          inline: false
        }

        [bio_field | fields]
      else
        fields
      end

    # Funding information fields
    fields =
      if last_funding_round = Map.get(funding, "last_funding_round") do
        funding_round_field = %{
          name: "Last Round",
          value: last_funding_round,
          inline: true
        }

        [funding_round_field | fields]
      else
        fields
      end

    fields =
      if last_funding_amount = Map.get(funding, "last_funding_amount") do
        amount_value = "$" <> Algora.Util.format_number_compact(last_funding_amount)

        amount_field = %{
          name: "Last Funding",
          value: amount_value,
          inline: true
        }

        [amount_field | fields]
      else
        fields
      end

    fields =
      if total_funding = Map.get(funding, "total_funding") do
        total_value = "$" <> Algora.Util.format_number_compact(total_funding)

        total_field = %{
          name: "Total Funding",
          value: total_value,
          inline: true
        }

        [total_field | fields]
      else
        fields
      end

    fields =
      if valuation = Map.get(funding, "valuation") do
        valuation_value = "$" <> Algora.Util.format_number_compact(valuation)

        valuation_field = %{
          name: "Valuation",
          value: valuation_value,
          inline: true
        }

        [valuation_field | fields]
      else
        fields
      end

    fields =
      if investors = Map.get(funding, "investors") do
        investors_value =
          if is_list(investors) and length(investors) > 0 do
            Enum.join(investors, ", ")
          else
            "None"
          end

        investors_field = %{
          name: "Investors",
          value:
            if(String.length(investors_value) > 1024,
              do: String.slice(investors_value, 0, 1021) <> "...",
              else: investors_value
            ),
          inline: false
        }

        [investors_field | fields]
      else
        fields
      end

    fields =
      if job_description = Map.get(payload, "job_description") do
        job_description_field = %{
          name: "Job Description",
          value: job_description,
          inline: false
        }

        [job_description_field | fields]
      else
        fields
      end

    fields =
      if candidate_description = Map.get(payload, "candidate_description") do
        candidate_description_field = %{
          name: "Candidate Description",
          value: candidate_description,
          inline: false
        }

        [candidate_description_field | fields]
      else
        fields
      end

    # Build embed
    embed = %{
      color: if(is_company_domain, do: 0x10B981, else: 0x64748B),
      title: "Inbound",
      fields: Enum.reverse(fields),
      timestamp: task.inserted_at
    }

    avatar_url = Map.get(website_metadata, "avatar_url") || Map.get(website_metadata, "favicon_url")

    # Add thumbnail if company logo exists
    embed =
      if avatar_url do
        Map.put(embed, :thumbnail, %{url: avatar_url})
      else
        embed
      end

    # Add author if company name exists
    embed =
      if company_name do
        author = %{name: company_name}

        author =
          if avatar_url do
            Map.put(author, :icon_url, avatar_url)
          else
            author
          end

        author =
          if website_url do
            Map.put(author, :url, website_url)
          else
            author
          end

        Map.put(embed, :author, author)
      else
        embed
      end

    # Add footer with source
    embed =
      if source = Map.get(payload, "source") do
        Map.put(embed, :footer, %{text: "Source: #{source}"})
      else
        embed
      end

    %{embeds: [embed]}
  end
end
