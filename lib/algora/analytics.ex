defmodule Algora.Analytics do
  def get_company_analytics(period \\ "30d") do
    days = String.replace(period, "d", "") |> String.to_integer()
    _since = DateTime.utc_now() |> DateTime.add(-days * 24 * 3600)

    # Mock data for demonstration
    %{
      total_companies: 150,
      companies_change: 12,
      companies_trend: :up,
      active_companies: 85,
      active_change: 5,
      active_trend: :up,
      avg_time_to_fill: 4.2,
      time_to_fill_change: -0.8,
      time_to_fill_trend: :down,
      contract_success_rate: 92,
      success_rate_change: 2,
      success_rate_trend: :up,
      companies: mock_companies()
    }
  end

  def get_funnel_data(_period \\ "30d") do
    # Mock funnel data
    %{
      registered: 100,
      card_saved: 75,
      contract_started: 50,
      released_renewed: 35,
      released_only: 10,
      disputed: 5
    }
  end

  defp mock_companies do
    [
      %{
        name: "TechCorp",
        handle: "techcorp",
        avatar_url: "https://example.com/avatar1.jpg",
        joined_at: ~U[2024-01-15 00:00:00Z],
        status: :active,
        total_contracts: 12,
        success_rate: 95,
        last_active_at: ~U[2024-03-18 14:30:00Z]
      }
      # Add more mock companies...
    ]
  end
end
