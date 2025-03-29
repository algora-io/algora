defmodule AlgoraWeb.ChallengesLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header

  def render(assigns) do
    ~H"""
    <Header.header />
    <div class="pt-24 mx-auto max-w-7xl px-6 lg:px-8">
      <h1 class="text-4xl font-bold font-display">Challenges</h1>
      <div class="flex flex-col gap-6 pt-16 md:grid md:grid-cols-3 md:pt-12">
        <.link
          class="group relative flex aspect-[1200/630] flex-1 rounded-2xl border-2 border-solid border-border bg-cover hover:no-underline"
          style="background-image:url(/images/challenges/golem/og.png)"
          navigate={~p"/challenges/golem"}
        >
        </.link>
        <.link
          class="group relative flex aspect-[1200/630] flex-1 rounded-2xl border-2 border-solid border-border bg-cover hover:no-underline"
          style="background-image:url(/images/challenges/tsperf/og.png)"
          navigate={~p"/challenges/tsperf"}
        >
        </.link>
        <.link
          class="group relative flex aspect-[1200/630] flex-1 rounded-2xl border-2 border-solid border-border bg-cover hover:no-underline"
          style="background-image:url(/images/challenges/prettier/og.png)"
          navigate={~p"/challenges/prettier"}
        >
        </.link>
      </div>
    </div>
    <Footer.footer />
    """
  end
end
