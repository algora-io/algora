defmodule AlgoraWeb.Data.PlatformStats do
  @moduledoc false

  # TODO: remove this module once we have all the data in the database

  @enforce_keys [:extra_completed_bounties, :extra_contributors, :extra_paid_out]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          extra_completed_bounties: non_neg_integer(),
          extra_contributors: non_neg_integer(),
          extra_paid_out: Money.t()
        }

  @spec new(map()) :: t()
  def new(params \\ %{}) do
    %__MODULE__{
      extra_completed_bounties: to_integer(params["extra_completed_bounties"]),
      extra_contributors: to_integer(params["extra_contributors"]),
      extra_paid_out: to_money(params["extra_paid_out"])
    }
  end

  @spec get() :: t()
  def get do
    :algora
    |> :code.priv_dir()
    |> Path.join("dev/platform_stats.json")
    |> read_json_file()
    |> new()
  end

  @spec read_json_file(Path.t()) :: map()
  defp read_json_file(path) do
    with {:ok, contents} <- File.read(path),
         {:ok, json} <- Jason.decode(contents) do
      json
    else
      _ -> %{}
    end
  end

  @spec to_integer(any()) :: non_neg_integer()
  defp to_integer(value) when is_integer(value) and value >= 0, do: value
  defp to_integer(_), do: 0

  @spec to_money(any()) :: Money.t()
  defp to_money(value) when is_integer(value) and value >= 0 do
    Money.new(:USD, value, no_fraction_if_integer: true)
  end

  defp to_money(_), do: Money.new(:USD, 0)
end
