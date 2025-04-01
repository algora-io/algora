defmodule AlgoraWeb.OG.BountyLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Bounties.Bounty
  alias Algora.Repo

  def mount(%{"id" => id}, _session, socket) do
    bounty =
      Bounty
      |> Repo.get!(id)
      |> Repo.preload([:owner, :creator, :transactions, ticket: [repository: [:user]]])

    {host, ticket_ref} =
      if bounty.ticket.repository do
        {bounty.ticket.repository.user,
         %{
           owner: bounty.ticket.repository.user.provider_login,
           repo: bounty.ticket.repository.name,
           number: bounty.ticket.number
         }}
      else
        {bounty.owner, nil}
      end

    {:ok,
     socket
     |> assign(:bounty, bounty)
     |> assign(:host, host)
     |> assign(:ticket_ref, ticket_ref)}
  end

  def render(assigns) do
    ~H"""
    <div class="relative flex h-[630px] w-[1200px] flex-col bg-[#0A0A0A] p-8 border-l-[1rem] border-emerald-400">
      <div class="absolute left-[3rem] top-8 text-2xl font-display font-medium text-muted-foreground">
        algora.io
      </div>
      <div
        :if={@bounty.ticket.repository}
        class="absolute right-8 top-8 font-display text-2xl font-medium text-muted-foreground"
      >
        {@bounty.ticket.repository.name}#{@bounty.ticket.number}
      </div>
      <div class="flex flex-col items-center text-center">
        <div class="relative">
          <img src={@host.avatar_url} class="relative h-40 w-40 rounded-full bg-black" alt="Algora" />
        </div>
        <div class="mt-4 flex flex-col items-center font-display">
          <p class="text-7xl font-semibold text-foreground">
            {@host.provider_login}
          </p>
          <h1 class="mt-4 text-8xl font-extrabold tracking-tight text-white">
            <span class="text-emerald-400">
              {Money.to_string!(@bounty.amount, no_fraction_if_integer: true)}
            </span>
            Bounty
          </h1>
        </div>
      </div>

      <h2 class="mt-12 text-center text-4xl font-semibold text-foreground/90 line-clamp-3 leading-[3.5rem]">
        {@bounty.ticket.title}
      </h2>
    </div>
    """
  end
end
