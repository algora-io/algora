defmodule AlgoraWeb.Components.ModalVideo do
  @moduledoc false
  use AlgoraWeb.Component

  import AlgoraWeb.CoreComponents

  attr :src, :string, required: true
  attr :poster, :string, required: true
  attr :title, :string, default: nil
  attr :alt, :string, default: nil
  attr :class, :string, default: nil
  attr :autoplay, :boolean, default: true
  attr :start, :integer, default: 0
  attr :loading, :string, default: "lazy"

  def modal_video(assigns) do
    ~H"""
    <div
      class={
        classes([
          "group relative aspect-video w-full overflow-hidden rounded-xl lg:rounded-2xl bg-gray-800 cursor-pointer",
          @class
        ])
      }
      phx-click={
        %JS{}
        |> JS.set_attribute({"src", @src <> "?autoplay=#{@autoplay}&start=#{@start}"},
          to: "#video-modal-iframe"
        )
        |> JS.set_attribute({"title", @title}, to: "#video-modal-iframe")
        |> show_modal("video-modal")
      }
    >
      <img src={@poster} alt={@alt} class="object-cover w-full h-full" loading={@loading} />
      <div class="absolute inset-0 flex items-center justify-center">
        <div class="size-10 sm:size-16 rounded-full bg-black/50 flex items-center justify-center group-hover:bg-black/70 transition-colors">
          <.icon name="tabler-player-play-filled" class="size-5 sm:size-8 text-white" />
        </div>
      </div>
    </div>
    """
  end

  def modal_video_dialog(assigns) do
    ~H"""
    <.dialog
      id="video-modal"
      show={false}
      class="aspect-video h-full sm:h-auto w-full lg:max-w-none p-2 sm:p-4 lg:p-[5rem]"
      on_cancel={
        %JS{}
        |> JS.set_attribute({"src", ""}, to: "#video-modal-iframe")
        |> JS.set_attribute({"title", ""}, to: "#video-modal-iframe")
      }
    >
      <.dialog_content class="flex items-center justify-center">
        <iframe
          id="video-modal-iframe"
          frameborder="0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          referrerpolicy="strict-origin-when-cross-origin"
          allowfullscreen
          class="aspect-[9/16] sm:aspect-video w-full bg-black"
        >
        </iframe>
      </.dialog_content>
    </.dialog>
    """
  end
end
