import Ecto.Changeset
import Ecto.Query
import Money.Sigil

alias Algora.Accounts
alias Algora.Accounts.Identity
alias Algora.Accounts.User
alias Algora.Admin
alias Algora.Contracts
alias Algora.Contracts.Contract
alias Algora.Contracts.Timesheet
alias Algora.Github
alias Algora.Organizations
alias Algora.Organizations.Member
alias Algora.Payments
alias Algora.Payments.Account
alias Algora.Payments.Customer
alias Algora.Payments.PaymentMethod
alias Algora.Payments.Transaction
alias Algora.Repo

IEx.configure(inspect: [charlists: :as_lists, limit: :infinity], auto_reload: true)

defmodule Helpers do
  @moduledoc false
  def get_abstract_code(module) do
    f = ~c"./_build/dev/lib/algora/ebin/#{module}.beam"
    result = :beam_lib.chunks(f, [:abstract_code])
    {:ok, {_, [{:abstract_code, {_, ac}}]}} = result
    code = :erl_prettypr.format(:erl_syntax.form_list(ac))
    IO.puts(code)
    File.write!(~c".local/#{module}.erl", code)
  end
end
