defmodule Algora.Activities.Views do
  @moduledoc false
  alias Algora.Repo

  require Logger

  def render(%{type: type} = activity, template) when is_binary(type) do
    render(%{activity | type: String.to_existing_atom(type)}, template)
  end

  def render(%{type: :identity_created}, :title) do
    "An identity has been linked on Algora"
  end

  def render(%{type: :identity_created, assoc: identity} = activity, :txt) do
    """
    An identity from #{identity.provider} has been linked on algora.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :bounty_posted, assoc: bounty}, :title) do
    bounty = Repo.preload(bounty, :creator)
    "#{bounty.amount} bounty posted by #{bounty.creator.name}"
  end

  def render(%{type: :bounty_posted, assoc: bounty} = activity, :txt) do
    bounty = Repo.preload(bounty, :creator)

    """
    A new bounty has been posted by #{bounty.creator.name}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :bounty_repriced, assoc: _bounty}, :title) do
    "Reward updated for a bounty posted to Algora"
  end

  def render(%{type: :bounty_repriced, assoc: bounty} = activity, :txt) do
    bounty = Repo.preload(bounty, ticket: :repository)

    """
    A Bounty for #{bounty.ticket.repository.name} had it's reward updated to #{bounty.amount}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :claim_approved, assoc: _claim}, :title) do
    "A claim has been approved on Algora"
  end

  def render(%{type: :claim_approved, assoc: claim} = activity, :txt) do
    claim = Repo.preload(claim, :target)

    """
    A claim for the issue "#{claim.target.title}" was accepted.

    #{claim.url}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :claim_submitted, assoc: _claim}, :title) do
    "A claim has been submitted on Algora"
  end

  def render(%{type: :claim_submitted, assoc: claim} = activity, :txt) do
    claim = Repo.preload(claim, :target)

    """
    A claim for the issue "#{claim.target.title}" was submitted.

    #{claim.url}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :contract_created, assoc: _contract}, :title) do
    "A contract has been created on Algora"
  end

  def render(%{type: :contract_created, assoc: contract} = activity, :txt) do
    contract = Repo.preload(contract, [:client, :contractor])

    """
    A contract between #{contract.client.name} and #{contract.contractor.name} has been created.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :contract_prepaid, assoc: _contract}, :title) do
    "A contract has been prepaid on Algora"
  end

  def render(%{type: :contract_prepaid, assoc: contract} = activity, :txt) do
    contract = Repo.preload(contract, :client)

    """
    A contract for "#{contract.client.name}" has been prepaid.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :contract_renewed, assoc: _contract}, :title) do
    "A contract has been renewed on Algora"
  end

  def render(%{type: :contract_renewed, assoc: contract} = activity, :txt) do
    contract = Repo.preload(contract, [:client, :contractor])

    """
    A contract between "#{contract.client.name}" and "#{contract.contractor.name}" has been renewed.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :transaction_succeeded, assoc: tx} = activity, template) do
    tx = Repo.preload(tx, [:user, linked_transaction: [:user]])
    activity = %{activity | assoc: tx}

    case tx do
      %{linked_transaction: nil} ->
        Logger.error("Unknown transaction type: #{inspect(tx)}")
        raise "Unknown transaction type: #{inspect(tx)}"

      %{bounty_id: bounty_id} when not is_nil(bounty_id) ->
        render_transaction_succeeded(activity, template, :bounty)

      %{tip_id: tip_id} when not is_nil(tip_id) ->
        render_transaction_succeeded(activity, template, :tip)

      %{contract_id: contract_id} when not is_nil(contract_id) ->
        render_transaction_succeeded(activity, template, :contract)

      _ ->
        Logger.error("Unknown transaction type: #{inspect(tx)}")
        raise "Unknown transaction type: #{inspect(tx)}"
    end
  end

  defp render_transaction_succeeded(%{assoc: tx}, :title, :bounty) do
    "🎉 #{tx.net_amount} bounty awarded by #{tx.linked_transaction.user.name}"
  end

  defp render_transaction_succeeded(%{assoc: tx}, :title, :tip) do
    "💸 #{tx.net_amount} tip received from #{tx.linked_transaction.user.name}"
  end

  defp render_transaction_succeeded(%{assoc: tx}, :title, :contract) do
    "💰 #{tx.net_amount} contract paid by #{tx.linked_transaction.user.name}"
  end

  defp render_transaction_succeeded(%{assoc: tx}, :txt, :bounty) do
    """
    Congratulations, you've been awarded a #{tx.net_amount} bounty by #{tx.linked_transaction.user.name}!
    """
  end

  defp render_transaction_succeeded(%{assoc: tx}, :txt, :tip) do
    """
    Congratulations, you've been awarded a #{tx.net_amount} tip by #{tx.linked_transaction.user.name}!
    """
  end

  defp render_transaction_succeeded(%{assoc: tx}, :txt, :contract) do
    """
    Congratulations, you've been awarded a #{tx.net_amount} contract by #{tx.linked_transaction.user.name}!
    """
  end
end
