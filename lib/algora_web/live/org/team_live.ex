defmodule AlgoraWeb.Org.TeamLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias Algora.Accounts.User
  alias Algora.Organizations

  def mount(%{"org_handle" => handle}, _session, socket) do
    org = Organizations.get_org_by_handle!(handle)
    members = Organizations.list_org_members(org)
    contractors = Organizations.list_org_contractors(org)

    {:ok,
     socket
     |> assign(:page_title, "Team")
     |> assign(:org, org)
     |> assign(:members, members)
     |> assign(:contractors, contractors)}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto max-w-7xl space-y-6 p-6">
      <div class="space-y-1">
        <h1 class="text-2xl font-bold">Team</h1>
        <p class="text-muted-foreground">Manage your organization's team members and contractors</p>
      </div>

      <.card>
        <.card_header>
          <.card_title>Members</.card_title>
          <.card_description>People who are part of your organization</.card_description>
        </.card_header>
        <.card_content>
          <div class="-mx-6 overflow-x-auto">
            <div class="inline-block min-w-full py-2 align-middle">
              <table class="min-w-full divide-y divide-border">
                <thead>
                  <tr>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">Member</th>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">Role</th>
                    <th scope="col" class="px-6 py-3.5 text-left text-sm font-semibold">Joined</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-border">
                  <tr :for={member <- @members}>
                    <td class="whitespace-nowrap px-6 py-4">
                      <div class="flex items-center gap-3">
                        <.avatar>
                          <.avatar_image src={member.user.avatar_url} />
                          <.avatar_fallback>
                            {String.slice(member.user.handle, 0, 2)}
                          </.avatar_fallback>
                        </.avatar>
                        <div>
                          <div class="font-medium">{member.user.name}</div>
                          <div class="text-sm text-muted-foreground">@{member.user.handle}</div>
                        </div>
                      </div>
                    </td>
                    <td class="whitespace-nowrap px-6 py-4">
                      <.badge>
                        {member.role |> Atom.to_string() |> String.capitalize()}
                      </.badge>
                    </td>
                    <td class="whitespace-nowrap px-6 py-4 text-sm text-muted-foreground">
                      {Calendar.strftime(member.inserted_at, "%B %d, %Y")}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </.card_content>
      </.card>

      <.card :if={length(@contractors) > 0}>
        <.card_header>
          <.card_title>Contractors</.card_title>
          <.card_description>External contractors working with your organization</.card_description>
        </.card_header>
        <.card_content>
          <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <.card :for={contractor <- @contractors}>
              <.card_header class="space-y-0 pb-2">
                <div class="flex items-center gap-3">
                  <.avatar>
                    <.avatar_image src={contractor.avatar_url} />
                    <.avatar_fallback>{String.slice(contractor.handle, 0, 2)}</.avatar_fallback>
                  </.avatar>
                  <div>
                    <.card_title class="text-base">
                      {contractor.name}
                    </.card_title>
                    <.card_description>@{contractor.handle}</.card_description>
                  </div>
                </div>
              </.card_header>
              <.card_content>
                <div class="text-sm">
                  <p class="line-clamp-2 text-muted-foreground">
                    {contractor.bio || "No bio provided"}
                  </p>
                </div>
              </.card_content>
              <.card_footer>
                <.button variant="outline" class="w-full">
                  <.link navigate={User.url(contractor)}>View Profile</.link>
                </.button>
              </.card_footer>
            </.card>
          </div>
        </.card_content>
      </.card>
    </div>
    """
  end
end
