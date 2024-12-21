defmodule AlgoraEvent.Company.Events do
  defmodule Created do
    @derive Jason.Encoder
    defstruct [:uid, :user, :url]
  end

  defmodule Visited do
    @derive Jason.Encoder
    defstruct [:uid, :visit_count, :user, :url]
  end
end
