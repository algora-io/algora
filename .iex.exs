import Ecto.Changeset
import Ecto.Query
import Money.Sigil

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
alias Algora.Users
alias Algora.Users.Identity
alias Algora.Users.User

IEx.configure(inspect: [charlists: :as_lists, limit: :infinity], auto_reload: true)
