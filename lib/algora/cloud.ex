defmodule Algora.Cloud do
  @moduledoc false

  def top_contributions(github_handle) do
    call(AlgoraCloud, :top_contributions, [github_handle])
  end

  defp call(module, function, args) do
    if :code.which(module) == :non_existing do
      # TODO: call algora API
      {:error, :not_loaded}
    else
      apply(module, function, args)
    end
  end
end
