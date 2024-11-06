import Ecto.Query
import Ecto.Changeset

alias Algora.Admin
alias Algora.Accounts
alias Algora.Repo
alias Algora.Github

import AlgoraWeb.WebhooksController

IEx.configure(inspect: [charlists: :as_lists, limit: :infinity])

defmodule Helpers do
  def r(), do: IEx.Helpers.recompile()
end

import Helpers
