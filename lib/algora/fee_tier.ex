defmodule Algora.FeeTier do
  @moduledoc """
  Defines the fee tiers and helper functions for calculating fees based on payment volume.
  """

  @tiers [
    %{
      threshold: Money.new!(0, :USD, no_fraction_if_integer: true),
      fee: 19,
      progress_percent: 0.0
    },
    %{
      threshold: Money.new!(3_000, :USD, no_fraction_if_integer: true),
      fee: 15,
      progress_percent: 33.3
    },
    %{
      threshold: Money.new!(5_000, :USD, no_fraction_if_integer: true),
      fee: 10,
      progress_percent: 66.6
    },
    %{
      threshold: Money.new!(15_000, :USD, no_fraction_if_integer: true),
      fee: 5,
      progress_percent: 100.0
    }
  ]

  def all, do: @tiers

  def calculate_fee_percentage(total_paid) do
    # Find the highest tier where total_paid is greater than or equal to the threshold
    tier =
      @tiers
      |> Enum.reverse()
      |> Enum.find(List.first(@tiers), fn tier ->
        Money.compare!(total_paid, tier.threshold) in [:gt, :eq]
      end)

    tier.fee
  end

  def calculate_progress(total_paid) do
    tier = find_current_tier(total_paid)
    prev_tier = find_previous_tier(tier)
    next_threshold = if tier, do: tier.threshold, else: List.last(@tiers).threshold

    case {prev_tier, tier} do
      {nil, _tier} ->
        # First tier - calculate progress towards first threshold
        percentage_of(total_paid, next_threshold) * 100.0

      {_prev_tier, nil} ->
        # Beyond last tier
        100.0

      {prev_tier, _tier} ->
        # Between tiers - calculate progress between thresholds
        base_progress = prev_tier.progress_percent

        segment_progress =
          percentage_of(
            Money.sub!(total_paid, prev_tier.threshold),
            Money.sub!(next_threshold, prev_tier.threshold)
          ) * 100.0

        base_progress + segment_progress
    end
  end

  defp find_current_tier(total_paid) do
    Enum.find(@tiers, fn tier ->
      Money.compare!(total_paid, tier.threshold) == :lt
    end)
  end

  defp find_previous_tier(nil), do: List.last(@tiers)

  defp find_previous_tier(current_tier) do
    index = Enum.find_index(@tiers, &(&1 == current_tier))
    if index > 0, do: Enum.at(@tiers, index - 1)
  end

  defp percentage_of(amount, total) do
    amount
    |> Money.to_decimal()
    |> Decimal.div(Money.to_decimal(total))
    |> Decimal.to_float()
  end
end
