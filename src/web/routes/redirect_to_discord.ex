defmodule AlgoraWeb.RedirectToDiscord do
  use Phoenix.Controller

  def redirect_to_discord(conn, _params) do
    discord_invite_url = Application.get_env(:algora, :discord_invite_url)
    redirect(conn, external: discord_invite_url)
  end
end