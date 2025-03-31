defmodule AlgoraWeb.OG.BountyLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Bounties

  def mount(%{"id" => id}, _session, socket) do
    case Bounties.list_bounties(id: id) do
      [bounty | _] ->
        socket =
          socket
          |> assign(:bounty, bounty)
          |> assign(:ticket, bounty.ticket)

        {:ok, socket}

      [] ->
        {:ok, socket |> put_flash(:error, "Bounty not found") |> redirect(to: "/")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="relative flex h-[630px] w-[1200px] flex-col bg-[#0A0A0A] p-8 border-l-[1rem] border-emerald-400">
      <div class="absolute left-[3rem] top-8 text-2xl font-display font-medium text-muted-foreground">
        algora.io
      </div>
      <div class="absolute right-8 top-8 font-display text-2xl font-medium text-muted-foreground">
        {@bounty.repository.name}#{@ticket.number}
      </div>
      <div class="flex flex-col items-center text-center">
        <div class="relative">
          <img
            src={@bounty.owner.avatar_url}
            class="relative h-40 w-40 rounded-full bg-black"
            alt="Algora"
          />
        </div>
        <div class="mt-4 flex flex-col items-center font-display">
          <p class="text-7xl font-semibold text-foreground">
            {@bounty.owner.name}
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
        {@ticket.title}
      </h2>
      <%!-- <div class="mt-auto flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="text-xl font-medium text-emerald-300">
            algora.io
          </div>
          <div class="h-2 w-2 rounded-full bg-muted-foreground"></div>
          <div class="text-xl font-medium text-muted-foreground">
            Earn bounties for open source contributions
          </div>
        </div>
      </div> --%>
    </div>
    """
  end
end
