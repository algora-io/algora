defmodule Algora.FeeTier do
  @moduledoc """
  Defines the fee tiers and helper functions for calculating fees based on payment volume.
  """

  @tiers [
    %{
      threshold: Money.new!(0, :USD, no_fraction_if_integer: true),
      fee: Decimal.new("0.19"),
      progress: Decimal.new("0.00")
    },
    %{
      threshold: Money.new!(3_000, :USD, no_fraction_if_integer: true),
      fee: Decimal.new("0.15"),
      progress: Decimal.new("0.33")
    },
    %{
      threshold: Money.new!(5_000, :USD, no_fraction_if_integer: true),
      fee: Decimal.new("0.10"),
      progress: Decimal.new("0.66")
    },
    %{
      threshold: Money.new!(15_000, :USD, no_fraction_if_integer: true),
      fee: Decimal.new("0.05"),
      progress: Decimal.new("1.00")
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
        percentage_of(total_paid, next_threshold)

      {_prev_tier, nil} ->
        # Beyond last tier
        Decimal.new("1.00")

      {prev_tier, _tier} ->
        # Between tiers - calculate progress between thresholds
        base_progress = prev_tier.progress

        segment_progress =
          percentage_of(
            Money.sub!(total_paid, prev_tier.threshold),
            Money.sub!(next_threshold, prev_tier.threshold)
          )

        Decimal.add(base_progress, segment_progress)
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
  end
end
