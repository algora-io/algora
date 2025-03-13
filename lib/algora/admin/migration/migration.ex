defmodule Algora.Admin.Migration do
  @moduledoc """
  Database Migration Script

  Purpose:
  This script processes a PostgreSQL database dump in COPY format,
  transforms the data according to new schema requirements, and outputs
  the result in the same COPY format.

  Functionality:
  1. Dumps the PostgreSQL database from MIGRATION_URL environment variable
  2. Reads a PostgreSQL dump file containing COPY statements and their associated data.
  3. Processes each COPY section (extract, transform, load).
  4. Applies transformations based on table names.
  5. Outputs the transformed data in COPY format.
  6. Discards COPY sections for tables not in the allowed list.

  Usage:
  - Set the MIGRATION_URL environment variable to the source database URL
  - Run the script using: elixir scripts/database_migration.exs
  """
  alias Algora.Accounts.Identity
  alias Algora.Accounts.User
  alias Algora.Admin
  alias Algora.Bounties.Attempt
  alias Algora.Bounties.Bounty
  alias Algora.Bounties.Claim
  alias Algora.Bounties.Tip
  alias Algora.Organizations.Member
  alias Algora.Payments.Account
  alias Algora.Payments.Customer
  alias Algora.Payments.PaymentMethod
  alias Algora.Payments.Transaction
  alias Algora.Workspace.CommandResponse
  alias Algora.Workspace.Installation
  alias Algora.Workspace.Ticket

  require Logger

  @schema_mappings [
    {"User", User},
    {"Org", User},
    {"GithubUser", User},
    {"Account", Identity},
    {"OrgMember", Member},
    {"Task", Ticket},
    {"GithubIssue", nil},
    {"GithubPullRequest", nil},
    {"Bounty", Bounty},
    {"Bounty", CommandResponse},
    {"Reward", nil},
    {"Attempt", Attempt},
    {"Claim", Claim},
    {"BountyCharge", Transaction},
    {"BountyTransfer", Tip},
    {"BountyTransfer", Transaction},
    {"OrgBalanceTransaction", Transaction},
    {"GithubInstallation", Installation},
    {"StripeAccount", Account},
    {"StripeCustomer", Customer},
    {"StripePaymentMethod", PaymentMethod}
  ]

  @index_fields [
    {"User", ["id"]},
    {"GithubUser", ["id", "user_id"]},
    {"Bounty", ["id"]},
    {"Task", ["id"]},
    {"Claim", ["id"]},
    {"BountyCharge", ["id"]},
    {"StripeCustomer", ["org_id"]},
    {"GithubIssue", ["id"]},
    {"GithubPullRequest", ["id", "task_id"]},
    {"Reward", ["bounty_id"]}
  ]

  @test_orgs ["cljo6j981000el60f1k1cvtns", "clcqf530c0001jy08mdisnzmj"]

  defp relevant_tables do
    @schema_mappings
    |> Enum.map(fn {k, _v} -> k end)
    |> Enum.dedup()
  end

  defp backfilled_tables do
    @schema_mappings
    |> Enum.map(fn {_, v} -> v end)
    |> Enum.reject(&is_nil/1)
    |> Enum.dedup()
    |> Enum.reverse()
    |> Enum.map(& &1.__schema__(:source))
  end

  defp transform({"Task", Ticket}, row, db) do
    if row["forge"] != "github" do
      raise "Unknown forge: #{row["forge"]}"
    end

    github_issue = find_by_index(db, "GithubIssue", "id", row["issue_id"])
    github_pull_request = find_by_index(db, "GithubPullRequest", "id", row["pull_request_id"])

    row =
      cond do
        github_issue ->
          %{
            "id" => row["id"],
            "provider" => "github",
            "provider_id" => github_issue["id"],
            "provider_meta" => deserialize_value(github_issue),
            "type" => "issue",
            "title" => github_issue["title"],
            "description" => github_issue["body"],
            "number" => github_issue["number"],
            "url" => github_issue["html_url"],
            "inserted_at" => github_issue["created_at"],
            "updated_at" => github_issue["updated_at"]
          }

        github_pull_request ->
          %{
            "id" => row["id"],
            "provider" => "github",
            "provider_id" => github_pull_request["id"],
            "provider_meta" => deserialize_value(github_pull_request),
            "type" => "pull_request",
            "title" => github_pull_request["title"],
            "description" => github_pull_request["body"],
            "number" => github_pull_request["number"],
            "url" => github_pull_request["html_url"],
            "inserted_at" => github_pull_request["created_at"],
            "updated_at" => github_pull_request["updated_at"]
          }

        true ->
          %{
            "id" => row["id"],
            "provider" => row["forge"],
            "provider_id" => nil,
            "provider_meta" => nil,
            "type" => "issue",
            "title" => row["title"],
            "description" => row["body"],
            "number" => row["number"],
            "url" => "https://github.com/#{row["repo_owner"]}/#{row["repo_name"]}/issues/#{row["number"]}",
            "inserted_at" => "1970-01-01 00:00:00",
            "updated_at" => "1970-01-01 00:00:00"
          }
      end

    row
  end

  defp transform({"User", User}, row, db) do
    # TODO: reenable
    # if !row["\"emailVerified\""] || String.length(row["\"emailVerified\""]) < 10 do
    #   raise "Email not verified: #{inspect(row)}"
    # end

    github_user = find_by_index(db, "GithubUser", "user_id", row["id"])

    %{
      "id" => row["id"],
      "provider" => github_user && "github",
      "provider_id" => github_user && github_user["id"],
      "provider_login" => github_user && github_user["login"],
      "provider_meta" => github_user && deserialize_value(github_user),
      "email" => row["email"],
      "display_name" => row["name"],
      "handle" => row["handle"],
      "avatar_url" => update_url(row["image"]),
      "type" => "individual",
      "bio" => github_user && github_user["bio"],
      "location" => row["loc"],
      "country" => row["country"],
      "timezone" => nil,
      "stargazers_count" => row["stars_earned"],
      "domain" => nil,
      "tech_stack" => row["tech"],
      "featured" => nil,
      "priority" => nil,
      "fee_pct" => nil,
      "seeded" => nil,
      "activated" => nil,
      "max_open_attempts" => nil,
      "manual_assignment" => nil,
      "bounty_mode" => nil,
      "hourly_rate_min" => nil,
      "hourly_rate_max" => nil,
      "hours_per_week" => nil,
      "website_url" => nil,
      "twitter_url" => nil,
      "github_url" => nil,
      "youtube_url" => row["youtube_handle"] && "https://www.youtube.com/#{row["youtube_handle"]}",
      "twitch_url" => row["twitch_handle"] && "https://www.twitch.tv/#{row["twitch_handle"]}",
      "discord_url" => nil,
      "slack_url" => nil,
      "linkedin_url" => nil,
      "og_title" => nil,
      "og_image_url" => nil,
      "last_context" => nil,
      "need_avatar" => nil,
      "inserted_at" => row["created_at"],
      "updated_at" => row["updated_at"],
      "last_active_at" => row["last_activity_at"],
      "is_admin" => row["is_admin"]
    }
  end

  defp transform({"Org", User}, row, db) do
    merged_user = find_by_index(db, "_MergedUser", "id", row["id"])

    if not user?(merged_user) do
      %{
        "id" => row["id"],
        "provider" => row["github_handle"] && "github",
        "provider_id" => row["github_id"],
        "provider_login" => row["github_handle"],
        "provider_meta" => row["github_data"] && deserialize_value(row["github_data"]),
        "email" => nil,
        "display_name" => row["name"],
        "handle" => row["handle"],
        "avatar_url" => update_url(row["avatar_url"]),
        "type" => "organization",
        "bio" => row["description"],
        "location" => nil,
        "country" => nil,
        "timezone" => nil,
        "stargazers_count" => row["stargazers_count"],
        "domain" => row["domain"],
        "tech_stack" => row["tech"],
        "featured" => row["featured"],
        "priority" => row["priority"],
        "fee_pct" => row["fee_pct"],
        "seeded" => row["seeded"],
        "activated" => row["active"],
        "max_open_attempts" => row["max_open_attempts"],
        "manual_assignment" => row["manual_assignment"],
        "bounty_mode" =>
          if true?(row["enabled_community_mode"]) do
            :community
          else
            :public
          end,
        "hourly_rate_min" => nil,
        "hourly_rate_max" => nil,
        "hours_per_week" => nil,
        "website_url" => row["website_url"],
        "twitter_url" => row["twitter_url"],
        "github_url" => nil,
        "youtube_url" => row["youtube_url"],
        "twitch_url" => nil,
        "discord_url" => row["discord_url"],
        "slack_url" => row["slack_url"],
        "linkedin_url" => nil,
        "og_title" => nil,
        "og_image_url" => nil,
        "last_context" => nil,
        "need_avatar" => nil,
        "inserted_at" => row["created_at"],
        "updated_at" => row["updated_at"],
        "is_admin" => false
      }
    end
  end

  defp transform({"GithubUser", User}, row, _db) do
    if nullish?(row["user_id"]) do
      %{
        "id" => row["id"],
        "provider" => "github",
        "provider_id" => row["id"],
        "provider_login" => row["login"],
        "provider_meta" => deserialize_value(row),
        "email" => nil,
        "display_name" => row["name"],
        "handle" => nil,
        "avatar_url" => row["avatar_url"],
        "type" =>
          case row["type"] do
            "Bot" -> "bot"
            "Organization" -> "organization"
            "User" -> "individual"
            _ -> raise "Unknown user type: #{inspect(row)}"
          end,
        "bio" => row["bio"],
        "location" => row["location"],
        "country" => nil,
        "timezone" => nil,
        "stargazers_count" => nil,
        "domain" => nil,
        "tech_stack" => nil,
        "featured" => nil,
        "priority" => nil,
        "fee_pct" => nil,
        "seeded" => nil,
        "activated" => nil,
        "max_open_attempts" => nil,
        "manual_assignment" => nil,
        "bounty_mode" => nil,
        "hourly_rate_min" => nil,
        "hourly_rate_max" => nil,
        "hours_per_week" => nil,
        "website_url" => nil,
        "twitter_url" => row["twitter_username"] && "https://www.twitter.com/#{row["twitter_username"]}",
        "github_url" => nil,
        "youtube_url" => nil,
        "twitch_url" => nil,
        "discord_url" => nil,
        "slack_url" => nil,
        "linkedin_url" => nil,
        "og_title" => nil,
        "og_image_url" => nil,
        "last_context" => nil,
        "need_avatar" => nil,
        "inserted_at" => row["retrieved_at"],
        "updated_at" => row["retrieved_at"],
        "is_admin" => nil
      }
    end
  end

  defp transform({"Account", Identity}, row, db) do
    user = find_by_index(db, "User", "id", row["\"userId\""])

    if !user do
      raise "User not found: #{inspect(row)}"
    end

    %{
      "id" => row["id"],
      "user_id" => user["id"],
      "provider" => row["provider"],
      "provider_token" => row["access_token"],
      "provider_email" => user["email"],
      "provider_login" => nil,
      "provider_id" => row["\"providerAccountId\""],
      "provider_meta" => nil,
      "inserted_at" => row["created_at"],
      "updated_at" => row["updated_at"]
    }
  end

  defp transform({"OrgMember", Member}, row, db) do
    owner = find_by_index(db, "_MergedUser", "id", row["org_id"])

    if !owner do
      raise "Owner not found: #{inspect(row)}"
    end

    if owner["id"] != row["user_id"] do
      %{
        "id" => row["id"],
        "org_id" => owner["id"],
        "role" => row["role"],
        "user_id" => row["user_id"],
        "inserted_at" => row["created_at"],
        "updated_at" => row["updated_at"]
      }
    end
  end

  defp transform({"Bounty", Bounty}, row, db) do
    reward = find_by_index(db, "Reward", "bounty_id", row["id"])
    owner = find_by_index(db, "_MergedUser", "id", row["org_id"])

    amount = if reward, do: Money.from_integer(String.to_integer(reward["amount"]), reward["currency"])

    if !owner do
      raise "Owner not found: #{inspect(row)}"
    end

    transfer = find_by_index(db, "_BountyTransfer", "bounty_id", row["id"])

    if row["type"] != "tip" and owner["id"] not in @test_orgs do
      %{
        "id" => row["id"],
        "amount" => amount,
        "status" =>
          cond do
            not is_nil(transfer) -> :paid
            true?(row["deleted"]) || row["status"] == "inactive" -> :cancelled
            true -> :open
          end,
        "ticket_id" => row["task_id"],
        "owner_id" => owner["id"],
        "creator_id" => row["poster_id"],
        "inserted_at" => row["created_at"],
        "updated_at" => row["updated_at"],
        "number" => row["number"],
        "autopay_disabled" => row["autopay_disabled"],
        "visibility" =>
          cond do
            row["visibility"] == "unlisted" -> :exclusive
            true?(owner["enabled_community_mode"]) -> :community
            true -> :public
          end
      }
    end
  end

  defp transform({"Bounty", CommandResponse}, row, _db) do
    if !nullish?(row["github_res_comment_id"]) do
      %{
        "id" => row["id"],
        "provider" => "github",
        "provider_meta" => nil,
        "provider_command_id" => row["github_req_comment_id"],
        "provider_response_id" => row["github_res_comment_id"],
        "command_source" => "comment",
        "command_type" => "bounty",
        "ticket_id" => row["task_id"],
        "inserted_at" => row["created_at"],
        "updated_at" => row["updated_at"]
      }
    end
  end

  defp transform({"Attempt", Attempt}, row, db) do
    bounty = find_by_index(db, "Bounty", "id", row["bounty_id"])
    github_user = find_by_index(db, "GithubUser", "id", row["github_user_id"])

    user_id = or_else(github_user["user_id"], github_user["id"])

    if !bounty do
      raise "Bounty not found: #{inspect(row)}"
    end

    if nullish?(user_id) do
      raise "User not found: #{inspect(row)}"
    end

    %{
      "id" => row["id"],
      "status" => row["status"],
      "warnings_count" => row["warnings_count"],
      "ticket_id" => bounty["task_id"],
      "user_id" => user_id,
      "inserted_at" => row["created_at"],
      "updated_at" => row["updated_at"]
    }
  end

  defp transform({"Claim", Claim}, row, db) do
    bounty = find_by_index(db, "Bounty", "id", row["bounty_id"])
    task = find_by_index(db, "Task", "id", bounty["task_id"])
    github_user = find_by_index(db, "GithubUser", "id", row["github_user_id"])

    user_id = or_else(github_user["user_id"], github_user["id"])

    if !task do
      raise "Task not found: #{inspect(row)}"
    end

    if nullish?(user_id) do
      raise "User not found: #{inspect(row)}"
    end

    %{
      "id" => row["id"],
      "status" =>
        case row["status"] do
          "accepted" -> :approved
          _ -> :pending
        end,
      "type" =>
        cond do
          !nullish?(row["github_pull_request_id"]) -> "pull_request"
          String.match?(row["github_url"], ~r{^https?://(?:www\.)?figma\.com/}) -> "design"
          true -> "pull_request"
        end,
      "url" => or_else(row["github_url"], "https://algora.io"),
      "group_id" => row["id"],
      "group_share" => nil,
      "source_id" => nil,
      "target_id" => task["id"],
      "user_id" => user_id,
      "inserted_at" => row["created_at"],
      "updated_at" => row["updated_at"]
    }
  end

  defp transform({"BountyCharge", Transaction}, row, db) do
    user = find_by_index(db, "_MergedUser", "id", row["org_id"])

    amount = Money.from_integer(String.to_integer(row["amount"]), row["currency"])

    if !user do
      raise "User not found: #{inspect(row)}"
    end

    if !nullish?(row["succeeded_at"]) and user["id"] not in @test_orgs do
      %{
        "id" => row["id"],
        "provider" => "stripe",
        "provider_id" => row["charge_id"],
        "provider_charge_id" => row["charge_id"],
        "provider_payment_intent_id" => nil,
        "provider_transfer_id" => nil,
        "provider_invoice_id" => nil,
        "provider_balance_transaction_id" => nil,
        "provider_meta" => nil,
        # TODO: incorrect
        "gross_amount" => amount,
        "net_amount" => amount,
        # TODO: incorrect
        "total_fee" => Money.zero(:USD),
        "provider_fee" => nil,
        "line_items" => nil,
        "type" => "charge",
        "status" => if(nullish?(row["succeeded_at"]), do: :initialized, else: :succeeded),
        "succeeded_at" => row["succeeded_at"],
        "reversed_at" => nil,
        "group_id" => row["id"],
        "user_id" => user["id"],
        "contract_id" => nil,
        "original_contract_id" => nil,
        "timesheet_id" => nil,
        "bounty_id" => nil,
        "tip_id" => nil,
        "linked_transaction_id" => nil,
        "inserted_at" => row["created_at"],
        "updated_at" => row["updated_at"],
        "claim_id" => nil
      }
    end
  end

  defp transform({"BountyTransfer", Tip}, row, db) do
    claim = find_by_index(db, "Claim", "id", row["claim_id"])
    github_user = find_by_index(db, "GithubUser", "id", claim["github_user_id"])
    bounty = find_by_index(db, "Bounty", "id", claim["bounty_id"])
    owner = find_by_index(db, "_MergedUser", "id", bounty["org_id"])
    bounty_charge = find_by_index(db, "BountyCharge", "id", row["bounty_charge_id"])
    user_id = or_else(github_user["user_id"], github_user["id"])
    amount = Money.from_integer(String.to_integer(row["amount"]), row["currency"])

    if !bounty do
      raise "Bounty not found: #{inspect(row)}"
    end

    if !bounty_charge do
      raise "BountyCharge not found: #{inspect(row)}"
    end

    if nullish?(user_id) do
      raise "User not found: #{inspect(row)}"
    end

    if !owner do
      raise "Owner not found: #{inspect(row)}"
    end

    if bounty["type"] == "tip" and !nullish?(bounty_charge["succeeded_at"]) and owner["id"] not in @test_orgs do
      %{
        "id" => bounty["id"] <> user_id,
        "amount" => amount,
        "status" => :paid,
        "ticket_id" => bounty["task_id"],
        "owner_id" => owner["id"],
        "creator_id" => bounty["poster_id"],
        "recipient_id" => user_id,
        "inserted_at" => bounty["created_at"],
        "updated_at" => bounty["updated_at"]
      }
    end
  end

  defp transform({"BountyTransfer", Transaction}, row, db) do
    claim = find_by_index(db, "Claim", "id", row["claim_id"])
    bounty = find_by_index(db, "Bounty", "id", claim["bounty_id"])
    github_user = find_by_index(db, "GithubUser", "id", claim["github_user_id"])
    org = find_by_index(db, "_MergedUser", "id", bounty["org_id"])
    bounty_charge = find_by_index(db, "BountyCharge", "id", row["bounty_charge_id"])

    user_id = or_else(github_user["user_id"], github_user["id"])

    if !bounty do
      raise "Bounty not found: #{inspect(row)}"
    end

    if nullish?(user_id) do
      raise "User not found: #{inspect(row)}"
    end

    if !org do
      raise "Org not found: #{inspect(row)}"
    end

    if !bounty_charge do
      raise "BountyCharge not found: #{inspect(row)}"
    end

    if !nullish?(bounty_charge["succeeded_at"]) and org["id"] not in @test_orgs do
      Enum.reject(
        [
          maybe_create_transaction("debit", %{
            bounty_charge: bounty_charge,
            bounty_transfer: row,
            bounty: bounty,
            claim: claim,
            org: org,
            user_id: user_id
          }),
          maybe_create_transaction("credit", %{
            bounty_charge: bounty_charge,
            bounty_transfer: row,
            bounty: bounty,
            claim: claim,
            org: org,
            user_id: user_id
          }),
          maybe_create_transaction("transfer", %{
            bounty_charge: bounty_charge,
            bounty_transfer: row,
            bounty: bounty,
            claim: claim,
            org: org,
            user_id: user_id
          })
        ],
        &is_nil/1
      )
    end
  end

  defp transform({"OrgBalanceTransaction", Transaction}, row, db) do
    user = find_by_index(db, "_MergedUser", "id", row["org_id"])

    if !user do
      raise "User not found: #{inspect(row)}"
    end

    amount = Money.from_integer(String.to_integer(row["amount"]), row["currency"])

    {abs_amount, type} =
      if Money.positive?(amount) do
        {amount, "credit"}
      else
        {Money.negate!(amount), "debit"}
      end

    if user["id"] not in @test_orgs do
      %{
        "id" => row["id"],
        "provider" => "stripe",
        "provider_id" => nil,
        "provider_charge_id" => nil,
        "provider_payment_intent_id" => nil,
        "provider_transfer_id" => nil,
        "provider_invoice_id" => nil,
        "provider_balance_transaction_id" => nil,
        "provider_meta" => nil,
        "gross_amount" => abs_amount,
        "net_amount" => abs_amount,
        "total_fee" => Money.zero(:USD),
        "provider_fee" => nil,
        "line_items" => nil,
        "type" => type,
        "status" => :succeeded,
        "succeeded_at" => row["created_at"],
        "reversed_at" => nil,
        "group_id" => row["id"],
        "user_id" => user["id"],
        "contract_id" => nil,
        "original_contract_id" => nil,
        "timesheet_id" => nil,
        "bounty_id" => nil,
        "tip_id" => nil,
        "linked_transaction_id" => nil,
        "inserted_at" => row["created_at"],
        "updated_at" => row["created_at"],
        "claim_id" => nil
      }
    end
  end

  defp transform({"GithubInstallation", Installation}, row, db) do
    connected_user = find_by_index(db, "_MergedUser", "id", row["org_id"])

    if !connected_user do
      raise "Connected user not found: #{inspect(row)}"
    end

    %{
      "id" => row["id"],
      "provider" => "github",
      "provider_id" => row["github_id"],
      "provider_meta" => nil,
      "avatar_url" => nil,
      "repository_selection" => nil,
      "owner_id" => nil,
      "connected_user_id" => connected_user["id"],
      "inserted_at" => row["created_at"],
      "updated_at" => row["updated_at"],
      "provider_user_id" => nil
    }
  end

  defp transform({"StripeAccount", Account}, row, _db) do
    %{
      "id" => row["id"],
      "provider" => "stripe",
      "provider_id" => row["id"],
      "provider_meta" => nil,
      "name" => nil,
      "details_submitted" => row["details_submitted"],
      "charges_enabled" => row["charges_enabled"],
      "service_agreement" => row["service_agreement"],
      "country" => row["country"],
      "type" => row["type"],
      "stale" => row["needs_refresh"],
      "user_id" => row["user_id"],
      "inserted_at" => row["created_at"],
      "updated_at" => row["updated_at"],
      "payouts_enabled" => row["charges_enabled"],
      "payout_interval" => nil,
      "payout_speed" => nil,
      "default_currency" => nil
    }
  end

  defp transform({"StripeCustomer", Customer}, row, db) do
    owner = find_by_index(db, "_MergedUser", "id", row["org_id"])

    if !owner do
      raise "Owner not found: #{inspect(row)}"
    end

    if owner["id"] not in @test_orgs do
      %{
        "id" => row["id"],
        "provider" => "stripe",
        "provider_id" => row["stripe_id"],
        "provider_meta" => nil,
        "name" => row["name"],
        "user_id" => owner["id"],
        "inserted_at" => row["created_at"],
        "updated_at" => row["updated_at"]
      }
    end
  end

  defp transform({"StripePaymentMethod", PaymentMethod}, row, db) do
    owner = find_by_index(db, "_MergedUser", "id", row["org_id"])

    if !owner do
      raise "Owner not found: #{inspect(row)}"
    end

    customer = find_by_index(db, "StripeCustomer", "org_id", row["org_id"])

    if !customer do
      raise "StripeCustomer not found: #{inspect(row)}"
    end

    if owner["id"] not in @test_orgs do
      %{
        "id" => row["id"],
        "provider" => "stripe",
        "provider_id" => row["stripe_id"],
        "provider_meta" => nil,
        "provider_customer_id" => customer["stripe_id"],
        "is_default" => row["is_default"],
        "customer_id" => customer["id"],
        "inserted_at" => row["created_at"],
        "updated_at" => row["updated_at"]
      }
    end
  end

  defp transform(_, _row, _db), do: nil

  defp maybe_create_transaction(type, %{
         bounty_charge: bounty_charge,
         bounty_transfer: bounty_transfer,
         bounty: bounty,
         claim: claim,
         org: org,
         user_id: user_id
       }) do
    amount = Money.from_integer(String.to_integer(bounty_transfer["amount"]), bounty_transfer["currency"])

    res = %{
      "id" => String.slice(type, 0, 2) <> "_" <> bounty_transfer["id"],
      "provider" => "stripe",
      "provider_id" => nil,
      "provider_charge_id" => bounty_charge["charge_id"],
      "provider_payment_intent_id" => nil,
      "provider_transfer_id" => bounty_transfer["transfer_id"],
      "provider_invoice_id" => nil,
      "provider_balance_transaction_id" => nil,
      "provider_meta" => nil,
      "gross_amount" => amount,
      "net_amount" => amount,
      "total_fee" => Money.zero(:USD),
      "provider_fee" => nil,
      "line_items" => nil,
      "type" => type,
      "status" => nil,
      "succeeded_at" => nil,
      "reversed_at" => nil,
      "group_id" => bounty_charge["id"],
      "user_id" => nil,
      "contract_id" => nil,
      "original_contract_id" => nil,
      "timesheet_id" => nil,
      "bounty_id" => nil,
      "tip_id" => nil,
      "linked_transaction_id" => nil,
      "inserted_at" => nil,
      "updated_at" => nil,
      "claim_id" => nil
    }

    res =
      if bounty["type"] == "tip" do
        Map.put(res, "tip_id", bounty["id"] <> user_id)
      else
        res
        |> Map.put("bounty_id", bounty["id"])
        |> Map.put("claim_id", claim["id"])
      end

    res =
      case type do
        "transfer" ->
          Map.merge(res, %{
            "user_id" => user_id,
            "provider_id" => bounty_transfer["transfer_id"]
          })

        "debit" ->
          Map.merge(res, %{
            "user_id" => org["id"],
            "linked_transaction_id" => "cr_" <> bounty_transfer["id"]
          })

        "credit" ->
          Map.merge(res, %{
            "user_id" => user_id,
            "linked_transaction_id" => "de_" <> bounty_transfer["id"]
          })

        _ ->
          res
      end

    cond do
      type == "transfer" && !nullish?(bounty_transfer["succeeded_at"]) ->
        Map.merge(res, %{
          "status" => :succeeded,
          "succeeded_at" => bounty_transfer["succeeded_at"],
          "inserted_at" => bounty_transfer["created_at"],
          "updated_at" => bounty_transfer["updated_at"]
        })

      type == "debit" && !nullish?(bounty_charge["succeeded_at"]) ->
        Map.merge(res, %{
          "status" => :succeeded,
          "succeeded_at" => bounty_charge["succeeded_at"],
          "inserted_at" => bounty_charge["succeeded_at"],
          "updated_at" => bounty_charge["succeeded_at"]
        })

      type == "credit" && !nullish?(bounty_charge["succeeded_at"]) ->
        Map.merge(res, %{
          "status" => :succeeded,
          "succeeded_at" => bounty_charge["succeeded_at"],
          "inserted_at" => bounty_charge["succeeded_at"],
          "updated_at" => bounty_charge["succeeded_at"]
        })

      true ->
        nil
    end
  end

  def process_dump(input_file, output_file) do
    db = collect_data(input_file)

    input_file
    |> File.stream!()
    |> Stream.chunk_while(
      [],
      &chunk_fun/2,
      &after_fun/1
    )
    |> Stream.filter(&(length(&1) > 0))
    |> Stream.map(&process_chunk(&1, db))
    |> Stream.into(File.stream!(output_file))
    |> Stream.run()
  end

  defp user?(row), do: not nullish?(row["email"])

  defp collect_data(input_file) do
    db =
      input_file
      |> File.stream!()
      |> Stream.chunk_while(
        nil,
        &collect_chunk_fun/2,
        &collect_after_fun/1
      )
      |> Enum.reduce(%{}, fn
        {table, data}, acc ->
          if table in relevant_tables() do
            parsed_data = parse_copy_data(data)
            Map.put(acc, table, parsed_data)
          else
            acc
          end
      end)

    indexes =
      Enum.reduce(@index_fields, %{}, fn {table, columns}, acc ->
        table_indexes = Map.new(columns, fn column -> {column, index_by_field(db, table, column)} end)
        Map.put(acc, table, table_indexes)
      end)

    db = Map.put(db, :indexes, indexes)

    db
    |> put_in([:indexes, "_MergedUser"], %{"id" => index_merged_users(db)})
    |> put_in([:indexes, "_BountyTransfer"], %{
      "bounty_id" =>
        db["BountyTransfer"]
        |> Enum.reject(fn row ->
          charge = find_by_index(db, "BountyCharge", "id", row["bounty_charge_id"])
          nullish?(charge["succeeded_at"])
        end)
        |> Enum.group_by(fn row ->
          claim = find_by_index(db, "Claim", "id", row["claim_id"])
          charge = find_by_index(db, "BountyCharge", "id", row["bounty_charge_id"])

          if charge["succeeded_at"] do
            claim["bounty_id"]
          end
        end)
    })
  end

  defp index_merged_users(db) do
    entities =
      (db["User"] ++ db["Org"])
      |> Enum.group_by(fn row ->
        if user?(row) do
          github_user = find_by_index(db, "GithubUser", "user_id", row["id"])

          if is_nil(github_user) or nullish?(github_user["login"]) do
            "algora_" <> row["id"]
          else
            "github_" <> github_user["login"]
          end
        else
          if nullish?(row["github_handle"]) do
            "algora_" <> row["id"]
          else
            "github_" <> row["github_handle"]
          end
        end
      end)
      |> Enum.flat_map(fn {_k, entities} ->
        case entities do
          [user] ->
            [{:unmerged, user["id"], user}]

          entities ->
            case Enum.find(entities, &user?/1) do
              nil ->
                raise "Unexpected number of users for #{inspect(entities)}"

              user ->
                Enum.map(entities, fn row ->
                  # if row["id"] != user["id"], do: Logger.info("[same github user] #{row["handle"]} -> #{user["handle"]}")
                  {:merged, row["id"], user}
                end)
            end
        end
      end)
      |> Enum.group_by(fn {type, _id, _user} -> type end)

    merged1 =
      entities
      |> Map.get(:merged, [])
      |> Map.new(fn {_type, id, user} -> {id, user} end)

    merged2 =
      entities
      |> Map.get(:unmerged, [])
      |> Enum.map(fn {_type, _id, row} -> row end)
      |> Enum.group_by(fn row -> row["handle"] end)
      |> Enum.flat_map(fn {handle, entities} ->
        case entities do
          [entity] ->
            [{entity["id"], entity}]

          [_entity1, _entity2] ->
            user = Enum.find(entities, &user?/1)
            org = Enum.find(entities, &(not user?(&1)))

            if is_nil(user) or is_nil(org) do
              raise "User or org not found for handle #{handle}: #{inspect(entities)}"
            end

            if org["creator_id"] == user["id"] do
              # Logger.info("[same handle] #{org["handle"]} -> #{user["handle"]}")
              Enum.map(entities, fn row -> {row["id"], user} end)
            else
              Logger.warning("Org #{org["handle"]} was not created by user #{user["handle"]}")
              Enum.map(entities, fn row -> {row["id"], row} end)
            end

          _ ->
            raise "Unexpected number of entities for handle #{handle}: #{inspect(entities)}"
        end
      end)
      |> Map.new()

    Map.merge(merged1, merged2)
  end

  defp index_by_field(db, table, field) do
    db[table]
    |> Enum.reject(fn row -> table == "StripeCustomer" and row["region"] == "EU" end)
    |> Enum.group_by(&Map.get(&1, field))
    |> Enum.reject(fn {k, _v} -> nullish?(k) end)
    |> Map.new(fn {k, v} ->
      {k,
       case v do
         [v] -> v
         v -> raise "Unexpected number of entities for #{table}.#{field}: #{inspect(v)}"
       end}
    end)
  end

  defp find_by_index(db, table, field, value) do
    case get_in(db, [:indexes, table, field]) do
      nil -> raise "Index not found for table #{table}.#{field}"
      index -> index[value]
    end
  end

  defp parse_copy_data([header | data]) do
    columns =
      header
      |> String.split("(")
      |> List.last()
      |> String.trim_trailing(") FROM stdin;\n")
      |> String.split(", ")

    Enum.map(data, fn line ->
      values = line |> String.trim() |> String.split("\t")
      columns |> Enum.zip(values) |> Map.new()
    end)
  end

  defp collect_chunk_fun(line, nil) do
    case Regex.run(~r/COPY public\.\"(\w+)\"/, line) do
      [_, table_name] -> {:cont, {table_name, [line]}}
      _ -> {:cont, nil}
    end
  end

  defp collect_chunk_fun(line, {table, acc}) do
    if String.trim(line) == "\\." do
      {:cont, {table, Enum.reverse(acc)}, nil}
    else
      {:cont, {table, [line | acc]}}
    end
  end

  defp collect_after_fun(nil), do: {:cont, nil}
  defp collect_after_fun({table, acc}), do: {:cont, {table, Enum.reverse(acc)}, nil}

  defp process_chunk(chunk, db) do
    case extract_copy_section(chunk) do
      %{table: table} = section ->
        @schema_mappings
        |> Enum.filter(fn {k, _v} -> k == table end)
        |> Enum.map(fn {_k, v} -> transform_section(section, v, db) end)
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&load_copy_section/1)

      _ ->
        []
    end
  end

  defp transform_section(%{table: table, columns: _columns, data: data}, schema, db) do
    transformed_data =
      data
      |> Enum.flat_map(fn row ->
        # try do
        case transform({table, schema}, row, db) do
          nil -> []
          xs when is_list(xs) -> xs
          x -> [x]
        end

        # rescue
        #   e ->
        #     IO.puts("Error transforming row in table #{table}: #{inspect(row)}")
        #     IO.puts("Error: #{inspect(e)}")
        #     nil
        # end
      end)
      |> Enum.map(&post_transform(schema, &1))

    if Enum.empty?(transformed_data) do
      nil
    else
      %{table: schema.__schema__(:source), columns: Map.keys(hd(transformed_data)), data: transformed_data}
    end
  end

  defp post_transform(schema, row) do
    default_fields =
      schema.__struct__()
      |> Map.from_struct()
      |> Map.take(schema.__schema__(:fields))

    default_fields =
      if schema == User do
        Map.delete(default_fields, :name)
      else
        default_fields
      end

    fields =
      row
      |> Enum.reject(fn {_, v} -> v == "\\N" end)
      |> Enum.reject(fn {_, v} -> v == nil end)
      |> Map.new(fn {k, v} -> {k, v} end)
      |> Map.take(Enum.map(Map.keys(default_fields), &Atom.to_string/1))
      |> Map.new(fn {k, v} -> {String.to_existing_atom(k), v} end)

    # TODO: do we need this?
    fields = ensure_unique_handle(fields)

    Map.merge(default_fields, fields)
  end

  defp ensure_unique_handle(fields) do
    if nullish?(fields[:handle]) do
      fields
    else
      new_handle = get_unique_handle(fields[:handle])
      Map.put(fields, :handle, new_handle)
    end
  end

  defp get_unique_handle(handle) do
    handles = Process.get(:handles, %{})
    downcased_handle = String.downcase(handle)
    count = Map.get(handles, downcased_handle, 0)

    new_handle = if count > 0, do: "#{handle}#{count + 1}", else: handle
    Process.put(:handles, Map.put(handles, downcased_handle, count + 1))

    if count > 0 do
      Logger.warning("Unique handle collision: #{handle} -> #{new_handle}")
    end

    new_handle
  end

  defp load_copy_section(%{table: table_name, columns: columns, data: data}) do
    copy_statement = "COPY #{table_name} (#{Enum.join(columns, ", ")}) FROM stdin;\n"

    data_lines =
      Enum.map(data, fn row ->
        columns
        |> Enum.map_join("\t", fn col -> serialize_value(Map.get(row, col, "")) end)
        |> Kernel.<>("\n")
      end)

    [copy_statement | data_lines] ++ ["\\.\n\n"]
  end

  defp serialize_value(%Money{} = value), do: "(#{value.currency},#{value.amount})"

  defp serialize_value(%Decimal{} = value), do: Decimal.to_string(value)

  defp serialize_value(value) when is_map(value) or is_list(value) do
    json = Jason.encode!(value, escape: :json)
    # Handle empty arrays specifically
    if json == "[]" do
      "{}"
    else
      # Escape backslashes and double quotes for PostgreSQL COPY
      String.replace(json, ["\\", "\""], fn
        "\\" -> "\\\\"
        "\"" -> "\\\""
      end)
    end
  rescue
    _ ->
      # Fallback to a safe string representation
      value
      |> inspect(limit: :infinity, printable_limit: :infinity)
      |> String.replace(["\\", "\n", "\r", "\t"], fn
        "\\" -> "\\\\"
        "\n" -> "\\n"
        "\r" -> "\\r"
        "\t" -> "\\t"
      end)
      |> String.replace("\"", "\\\"")
  end

  defp serialize_value(value) when is_nil(value), do: "\\N"

  defp serialize_value(value) when is_binary(value) do
    # Remove any surrounding quotes for numeric values
    value =
      if String.starts_with?(value, "\"") and String.ends_with?(value, "\"") do
        String.slice(value, 1..-2//1)
      else
        value
      end

    String.replace(value, ["\\", "\n", "\r", "\t"], fn
      "\\" -> "\\\\"
      "\n" -> "\\n"
      "\r" -> "\\r"
      "\t" -> "\\t"
    end)
  end

  defp serialize_value(value), do: to_string(value)

  # defp extract_default_fields(schema) do
  #   schema.__schema__(:fields)
  #   |> Enum.filter(fn field ->
  #     case schema.__schema__(:field, field) do
  #       {:default, _} -> true
  #       _ -> false
  #     end
  #   end)
  #   |> Enum.map(fn field ->
  #     {field, schema.__schema__(:field, field) |> elem(1)}
  #   end)
  #   |> Enum.into(%{})
  # end

  defp update_url(url) do
    case url do
      "/" <> rest -> "https://console.algora.io/" <> rest
      _ -> url
    end
  end

  defp chunk_fun(line, acc) do
    if String.starts_with?(line, "COPY ") or String.trim(line) == "\\." do
      {:cont, Enum.reverse(acc), [line]}
    else
      {:cont, [line | acc]}
    end
  end

  defp after_fun(acc), do: {:cont, Enum.reverse(acc), []}

  defp extract_copy_section([header | data]) do
    case Regex.run(~r/COPY (?:public\.)?\"?(\w+)\"?\s*\((.*?)\)\s*FROM stdin;/, header) do
      [_, table, column_string] ->
        columns = column_string |> String.split(", ") |> Enum.map(&String.trim/1)

        parsed_data =
          data
          |> Enum.take_while(&(&1 != "\\.\n"))
          |> Enum.map(&parse_data_row(&1, columns))

        %{table: table, columns: columns, data: parsed_data}

      nil ->
        nil
    end
  end

  defp parse_data_row(row, columns) do
    row
    |> String.trim()
    |> String.split("\t")
    |> Enum.zip(columns)
    |> Map.new(fn {value, column} -> {column, value} end)

    # |> Map.new(fn {value, column} -> {column, deserialize_value(value)} end)
  end

  defp deserialize_value("\\N"), do: nil
  defp deserialize_value("t"), do: true
  defp deserialize_value("f"), do: false
  defp deserialize_value("{}"), do: []

  defp deserialize_value(value) when is_map(value) do
    Map.new(value, fn {k, v} -> {k, deserialize_value(v)} end)
  end

  defp deserialize_value(value) when is_list(value) do
    Enum.map(value, &deserialize_value/1)
  end

  defp deserialize_value(value) when is_binary(value) do
    if String.starts_with?(value, "{") and String.ends_with?(value, "}") do
      value
      |> String.slice(1..-2//1)
      |> String.split(",", trim: true)
      |> Enum.map(&deserialize_value/1)
    else
      case Integer.parse(value) do
        {int, ""} ->
          int

        _ ->
          case Float.parse(value) do
            {float, ""} -> float
            _ -> value
          end
      end
    end
  end

  defp deserialize_value(value), do: value

  defp nullish?(value), do: is_nil(deserialize_value(value))

  defp true?(value), do: deserialize_value(value) == true

  defp or_else(value, default), do: if(nullish?(value), do: default, else: value)

  defp clear_tables! do
    commands =
      [
        "BEGIN TRANSACTION;",
        "SET CONSTRAINTS ALL DEFERRED;",
        Enum.map(backfilled_tables(), &"TRUNCATE TABLE #{&1} CASCADE;"),
        "SET CONSTRAINTS ALL IMMEDIATE;",
        "COMMIT;"
      ]
      |> List.flatten()
      |> Enum.join("\n")

    case psql(["-c", commands]) do
      {:ok, _} -> :ok
      {:error, code} -> raise "Failed to clear tables with exit code: #{code}"
    end
  end

  defp psql(commands) do
    {res, code} =
      System.cmd("psql", [System.fetch_env!("DATABASE_URL") | commands], stderr_to_stdout: true)

    cond do
      code != 0 ->
        Logger.error(res)
        {:error, code}

      String.contains?(res, "ERROR:") ->
        Logger.error(res)
        {:error, :something_went_wrong}

      true ->
        {:ok, res}
    end
  end

  defp time_step(description, function) do
    IO.puts("⏳ #{description}...")
    {time, result} = :timer.tc(function)
    IO.puts("✅ #{description} completed in #{time / 1_000_000} seconds")
    result
  end

  defp dump_database!(output_path) do
    {output, exit_code} =
      System.cmd(
        "pg_dump",
        [
          System.fetch_env!("MIGRATION_URL"),
          "-N",
          "supabase_functions",
          "-a",
          "-f",
          output_path
        ],
        stderr_to_stdout: true
      )

    if exit_code != 0 do
      Logger.error(output)
      raise "Failed to dump database with exit code: #{exit_code}"
    end

    :ok
  end

  def run!(timestamp \\ nil) do
    Algora.Settings.set_migration_in_progress!(true)

    pwd = Path.join([:code.priv_dir(:algora), "db"])
    File.mkdir_p!(pwd)

    timestamp = timestamp || Calendar.strftime(DateTime.utc_now(), "%Y-%m-%d-%H-%M-%S")
    input_path = Path.join(pwd, "v1-data-#{timestamp}.sql")
    output_path = Path.join(pwd, "v2-data-#{timestamp}.sql")

    IO.puts("⏳ Starting migration...")

    {total_time, _} =
      :timer.tc(fn ->
        :ok = time_step("Dumping database", fn -> dump_database!(input_path) end)
        :ok = time_step("Processing dump", fn -> process_dump(input_path, output_path) end)
        :ok = time_step("Clearing tables", fn -> clear_tables!() end)
        {:ok, _} = time_step("Importing new data", fn -> psql(["-f", output_path]) end)
        :ok = time_step("Backfilling repositories", fn -> Admin.backfill_repos!() end)
        :ok = time_step("Backfilling claims", fn -> Admin.backfill_claims!() end)
      end)

    IO.puts("✅ Migration completed successfully in #{total_time / 1_000_000} seconds")

    Algora.Settings.set_migration_in_progress!(false)
  end

  def reset! do
    clear_tables!()
  end
end
