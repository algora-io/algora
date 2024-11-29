import Ecto.Query
import Ecto.Changeset

alias Algora.Admin
alias Algora.Contracts.Contract
alias Algora.Github
alias Algora.Organizations.Member
alias Algora.Repo
alias Algora.Users
alias Algora.Users.{User, Identity}
alias Algora.Payments.{Customer, Account, PaymentMethod}

IEx.configure(inspect: [charlists: :as_lists, limit: :infinity])

defmodule Helpers do
  def r(), do: IEx.Helpers.recompile()
end

import Helpers
