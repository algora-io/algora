defmodule Algora.Activities.Views do
  @moduledoc false
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

  def render(%{type: :bounty_awarded, assoc: bounty}, :title) do
    "🎉 #{bounty.amount} bounty awarded by #{bounty.creator.display_name}"
  end

  def render(%{type: :bounty_awarded, assoc: bounty} = activity, :txt) do
    """
    Congratulations, you've been awarded a bounty by #{bounty.creator.display_name}!

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :bounty_posted, assoc: bounty}, :title) do
    "#{bounty.amount} bounty posted by #{bounty.creator.display_name}"
  end

  def render(%{type: :bounty_posted, assoc: bounty} = activity, :txt) do
    """
    A new bounty has been posted by #{bounty.creator.display_name}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :bounty_repriced}, :title) do
    "Reward updated for a bounty posted to Algora"
  end

  def render(%{type: :bounty_repriced, assoc: bounty} = activity, :txt) do
    """
    A Bounty for #{bounty.ticket.repository.name} had it's reward updated to #{bounty.amount}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :claim_approved}, :title) do
    "A claim has been approved on Algora"
  end

  def render(%{type: :claim_approved, assoc: claim} = activity, :txt) do
    """
    A claim for the issue "#{claim.target.title}" was accepted.

    #{claim.url}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :claim_submitted}, :title) do
    "A claim has been submitted on Algora"
  end

  def render(%{type: :claim_submitted, assoc: claim} = activity, :txt) do
    """
    A claim for the issue "#{claim.target.title}" was submitted.

    #{claim.url}

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :contract_created}, :title) do
    "A contract has been created on Algora"
  end

  def render(%{type: :contract_created, assoc: contract} = activity, :txt) do
    """
    A contract between #{contract.client.display_name} and #{contract.contractor.display_name} has been created.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :contract_paid}, :title) do
    "A contract has been paid on Algora"
  end

  def render(%{type: :contract_paid, assoc: contract} = activity, :txt) do
    """
    A contract between "#{contract.client.display_name}" and "#{contract.contractor.display_name}" has been paid.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :contract_prepaid}, :title) do
    "A contract has been prepaid on Algora"
  end

  def render(%{type: :contract_prepaid, assoc: contract} = activity, :txt) do
    """
    A contract for "#{contract.client.display_name}" has been prepaid.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :contract_renewed}, :title) do
    "A contract has been renewed on Algora"
  end

  def render(%{type: :contract_renewed, assoc: contract} = activity, :txt) do
    """
    A contract between "#{contract.client.display_name}" and "#{contract.contractor.display_name}" has been renewed.

    #{Algora.Activities.external_url(activity)}
    """
  end

  def render(%{type: :tip_awarded}, :title) do
    "You were awarded a tip on Algora"
  end

  def render(%{type: :tip_awarded, assoc: tip} = activity, :txt) do
    """
    #{tip.creator.display_name} sent you a #{tip.amount} tip on Algora!

    #{Algora.Activities.external_url(activity)}
    """
  end
end
