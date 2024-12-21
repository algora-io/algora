defmodule AlgoraEvent.Company.Commands do
  defmodule Create do
    @derive Jason.Encoder
    defstruct [:uid, :id, :user]
  end

  defmodule Visit do
    defstruct [:uid, :id, :user]
  end
end
