defmodule AlgoraWeb.Layouts do
  @moduledoc false
  use AlgoraWeb, :html

  embed_templates "layouts/*"

  attr :id, :string
  attr :current_user, :any
  attr :active_tab, :atom

  def sidebar_nav_links(assigns) do
    ~H"""
    <div class="space-y-1">
      <.link
        navigate="/"
        class={"#{if @active_tab == :home, do: "bg-gray-800", else: "hover:bg-gray-900"} group flex items-center rounded-md px-2 py-2 text-sm font-medium text-gray-200 hover:text-gray-50"}
        aria-current={if @active_tab == :home, do: "true", else: "false"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="mr-3 h-6 w-6 flex-shrink-0 text-gray-400 group-hover:text-gray-300"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M5 12l-2 0l9 -9l9 9l-2 0" /><path d="M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7" /><path d="M9 21v-6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v6" />
        </svg>
        Home
      </.link>
      <.link
        navigate={~p"/user/settings"}
        class={"#{if @active_tab == :settings, do: "bg-gray-800", else: "hover:bg-gray-900"} group flex items-center rounded-md px-2 py-2 text-sm font-medium text-gray-200 hover:text-gray-50"}
        aria-current={if @active_tab == :settings, do: "true", else: "false"}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="mr-3 h-6 w-6 flex-shrink-0 text-gray-400 group-hover:text-gray-300"
          width="24"
          height="24"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          fill="none"
          stroke-linecap="round"
          stroke-linejoin="round"
        >
          <path stroke="none" d="M0 0h24v24H0z" fill="none" /><path d="M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z" /><path d="M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0" />
        </svg>
        Settings
      </.link>
    </div>
    """
  end

  attr :id, :string
  attr :current_user, :any

  def sidebar_account_dropdown(assigns) do
    ~H"""
    <.dropdown id={@id}>
      <:img src={@current_user.avatar_url} alt={@current_user.handle} />
      <:title>{@current_user.name}</:title>
      <:subtitle>@{@current_user.handle}</:subtitle>
      <:link navigate={~p"/user/settings"}>Settings</:link>
      <:link href={~p"/auth/logout"} method={:delete}>Sign out</:link>
    </.dropdown>
    """
  end
end
