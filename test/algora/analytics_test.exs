defmodule Algora.AnalyticsTest do
  use Algora.DataCase

  import Algora.Factory

  setup do
    now = DateTime.utc_now()
    last_month = DateTime.add(now, -40 * 24 * 3600)

    Enum.reduce(1..100, now, fn _n, date ->
      insert(:organization, %{inserted_at: date, seeded: false, activated: false})
      DateTime.add(date, -1 * 24 * 3600)
    end)

    Enum.reduce(1..100, now, fn _n, date ->
      org = insert(:organization, %{inserted_at: date, seeded: true, activated: true})
      insert(:bounty, owner_id: org.id, status: :open, ticket: insert(:ticket))
      insert(:bounty, owner_id: org.id, status: :paid, ticket: insert(:ticket))
      insert(:bounty, owner_id: org.id, status: :cancelled, ticket: insert(:ticket))
      insert(:bounty, inserted_at: last_month, owner_id: org.id, status: :paid, ticket: insert(:ticket))
      insert(:bounty, inserted_at: last_month, owner_id: org.id, status: :cancelled, ticket: insert(:ticket))
      DateTime.add(date, -1 * 24 * 3600)
    end)

    :ok
  end

  # describe "analytics" do
  #   @tag :slow
  #   test "get_company_analytics 30d" do
  #     {:ok, resp} = Analytics.get_company_analytics("30d")
  #     assert resp.total_companies == 200
  #     assert resp.active_companies == 100
  #     assert resp.companies_change == 60
  #     assert resp.active_change == 30
  #     assert resp.companies_trend == :same
  #     assert resp.active_trend == :same
  #     assert resp.bounty_success_rate == 50.0
  #     assert resp.success_rate_change == 25.0
  #     assert resp.success_rate_trend == :up

  #     assert length(resp.companies) > 0

  #     assert %{total_bounties: 6, successful_bounties: 3, success_rate: 50.0, last_active_at: last_active_at} =
  #              List.first(resp.companies)

  #     assert DateTime.before?(last_active_at, DateTime.utc_now())

  #     now = DateTime.utc_now()
  #     last_month = DateTime.add(now, -40 * 24 * 3600)
  #     insert(:organization, %{inserted_at: last_month, seeded: true, activated: true})

  #     {:ok, resp} = Analytics.get_company_analytics("30d")
  #     assert resp.total_companies == 201
  #     assert resp.active_companies == 101
  #     assert resp.companies_change == 60
  #     assert resp.active_change == 30
  #     assert resp.companies_trend == :down
  #     assert resp.active_trend == :down

  #     insert(:organization, %{seeded: true, activated: true})
  #     insert(:organization, %{seeded: true, activated: true})
  #     insert(:organization, %{seeded: false, activated: false})

  #     {:ok, resp} = Analytics.get_company_analytics("30d")

  #     assert resp.total_companies == 204
  #     assert resp.active_companies == 103
  #     assert resp.companies_change == 63
  #     assert resp.active_change == 32
  #     assert resp.companies_trend == :up
  #     assert resp.active_trend == :up
  #   end

  #   @tag :slow
  #   test "get_company_analytics 356d" do
  #     {:ok, resp} = Analytics.get_company_analytics("365d")
  #     assert resp.total_companies == 200
  #     assert resp.active_companies == 100
  #     assert resp.companies_change == 200
  #     assert resp.active_change == 100
  #     assert resp.companies_trend == :up
  #     assert resp.active_trend == :up
  #   end

  #   @tag :slow
  #   test "get_company_analytics 7d" do
  #     insert(:organization, %{seeded: true, activated: true})
  #     {:ok, resp} = Analytics.get_company_analytics("7d")
  #     assert resp.total_companies == 201
  #     assert resp.active_companies == 101
  #     assert resp.companies_change == 15
  #     assert resp.active_change == 8
  #     assert resp.companies_trend == :up
  #     assert resp.active_trend == :up
  #   end
  # end
end
