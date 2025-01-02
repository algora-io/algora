defmodule AlgoraWeb.Components.ExpertCard do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  attr :github_handle, :string, required: true
  attr :name, :string, required: true
  attr :avatar_url, :string, required: true
  attr :location, :string, required: true
  attr :company, :string, required: true
  attr :bio, :string, required: true
  attr :twitter_handle, :string, required: true

  def expert_card(assigns) do
    ~H"""
    <a href={"https://github.com/#{@github_handle}"} target="_blank" rel="noopener">
      <div class="group/card from-white/[2%] via-white/[2%] to-white/[2%] bg-purple-200/[5%] relative h-full rounded-xl border border-white/10 bg-gradient-to-br hover:bg-purple-200/[7.5%] hover:border-white/15 md:gap-8">
        <div class="pointer-events-none">
          <div class="[mask-image:linear-gradient(black,transparent)] absolute inset-0 z-0 opacity-0 group-hover/card:opacity-100">
          </div>
          <div
            class="via-white/[2%] absolute inset-0 z-10 bg-gradient-to-br opacity-0 group-hover/card:opacity-100"
            style="mask-image: radial-gradient(240px at 476px 41.4px, white, transparent);"
          >
          </div>
          <div
            class="absolute inset-0 z-10 opacity-0 mix-blend-overlay group-hover/card:opacity-100"
            style="mask-image: radial-gradient(240px at 476px 41.4px, white, transparent);"
          >
          </div>
        </div>
        <div class="relative flex flex-col items-center overflow-hidden px-5 py-6">
          <span class="relative flex h-16 w-16 shrink-0 items-center justify-center overflow-hidden rounded-full sm:h-24 sm:w-24">
            <img class="aspect-square h-full w-full" alt={@name} src={@avatar_url} />
          </span>
          <div class="flex flex-col items-center gap-2 pt-2 text-center">
            <div>
              <span class="block text-lg font-semibold text-white sm:text-xl">
                {@name}
              </span>

              <div class="flex flex-wrap items-center justify-center gap-x-3 gap-y-1 pt-1 text-xs text-gray-300 sm:text-sm">
                <div :if={@twitter_handle} class="flex items-center gap-1">
                  <.icon name="tabler-brand-twitter" class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@twitter_handle}</span>
                </div>
                <div :if={@location} class="flex items-center gap-1">
                  <.icon name="tabler-map-pin" class="h-4 w-4" />
                  <span class="whitespace-nowrap">{@location}</span>
                </div>
                <div :if={@company} class="flex items-center gap-1">
                  <.icon name="tabler-building" class="h-4 w-4" />
                  <span class="whitespace-nowrap">
                    {@company |> String.trim_leading("@")}
                  </span>
                </div>
              </div>

              <span class="line-clamp-3 pt-2 text-xs text-gray-300 sm:text-sm">
                {@bio}
              </span>
            </div>
          </div>
        </div>
      </div>
    </a>
    """
  end
end
