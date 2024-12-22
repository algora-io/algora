import Ecto.Query
import Ecto.Changeset

alias Algora.{Admin, Github, Repo}

alias Algora.Contracts
alias Algora.Contracts.{Contract, Timesheet}
alias Algora.Organizations
alias Algora.Organizations.Member
alias Algora.Payments
alias Algora.Payments.{Customer, Account, PaymentMethod, Transaction}
alias Algora.Users
alias Algora.Users.{User, Identity}

IEx.configure(inspect: [charlists: :as_lists, limit: :infinity])

defmodule Helpers do
  require Logger

  def r() do
    try do
      IEx.Helpers.recompile()
    rescue
      e -> Logger.warning("Warning: #{inspect(e)}")
    end

    r(Algora.Github.Command)
  end
end

import Helpers
import Money.Sigil
