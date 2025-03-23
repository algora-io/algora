defmodule AlgoraWeb.Router do
  use AlgoraWeb, :router

  import AlgoraWeb.Analytics, only: [fetch_current_country: 2, fetch_current_page: 2]
  import AlgoraWeb.RedirectPlug
  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2, require_authenticated_admin: 2]
  import Oban.Web.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_user
    plug :fetch_current_page
    plug :fetch_current_country
    plug :put_root_layout, {AlgoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  @redirects Application.compile_env(:algora, :redirects, [])

  for {from, to} <- @redirects do
    redirect(from, to, :temporary)
  end

  scope "/" do
    forward "/asset", AlgoraWeb.Plugs.RewriteAssetsPlug,
      upstream: "#{Application.compile_env(:algora, :assets_url)}",
      response_mode: :buffer

    forward "/ingest", AlgoraWeb.Plugs.RewriteIngestPlug,
      upstream: "#{Application.compile_env(:algora, :ingest_url)}",
      response_mode: :buffer

    # forward "/docs", AlgoraWeb.Plugs.RewriteDocsPlug,
    #   upstream: "https://docs.algora.io",
    #   response_mode: :buffer
  end

  scope "/admin", AlgoraWeb do
    pipe_through [:browser]

    live_session :admin,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_admin}, AlgoraWeb.Admin.Nav] do
      live "/", Admin.AdminLive
      live "/leaderboard", Admin.LeaderboardLive
    end

    oban_dashboard("/oban", resolver: AlgoraWeb.ObanDashboardResolver)
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser]

    get "/", RootController, :index
    get "/og/*path", OGImageController, :generate
    get "/set_context/:context", ContextController, :set
    get "/a/:table_prefix/:activity_id", ActivityController, :get
    get "/auth/logout", OAuthCallbackController, :sign_out
    get "/tip", TipController, :create
    get "/preview", OrgPreviewCallbackController, :new

    scope "/callbacks" do
      get "/stripe/refresh", StripeCallbackController, :refresh
      get "/stripe/return", StripeCallbackController, :return
      get "/:provider/oauth", OAuthCallbackController, :new
      get "/:provider/installation", InstallationCallbackController, :new
    end

    scope "/go/:repo_owner/:repo_name" do
      live_session :preview,
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Org.PreviewNav] do
        live "/", Org.DashboardLive, :preview
      end
    end

    scope "/org/:org_handle" do
      live_session :org,
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Org.Nav] do
        live "/", Org.DashboardLive, :index
        live "/home", Org.HomeLive, :index
        live "/bounties", Org.BountiesLive, :index
        live "/contracts/:id", Contract.ViewLive
        live "/team", Org.TeamLive, :index
        live "/leaderboard", Org.LeaderboardLive, :index
      end

      live_session :org_admin,
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [
          {AlgoraWeb.UserAuth, :ensure_authenticated},
          {AlgoraWeb.UserAuth, :current_user},
          AlgoraWeb.Org.Nav,
          {AlgoraWeb.OrgAuth, :ensure_admin}
        ] do
        live "/settings", Org.SettingsLive, :edit
        live "/transactions", Org.TransactionsLive, :index
      end
    end

    live_session :authenticated,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_authenticated}, AlgoraWeb.User.Nav] do
      live "/home", User.DashboardLive, :index
      live "/user/transactions", User.TransactionsLive, :index
      live "/user/settings", User.SettingsLive, :edit
      live "/user/installations", User.InstallationsLive, :index
    end

    live_session :public,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.User.Nav] do
      live "/bounties", BountiesLive, :index
      live "/community", CommunityLive, :index
      live "/leaderboard", LeaderboardLive, :index
      live "/projects", OrgsLive, :index
      live "/@/:handle", User.ProfileLive, :index
      live "/claims/:group_id", ClaimLive
      live "/payment/success", Payment.SuccessLive, :index
      live "/payment/canceled", Payment.CanceledLive, :index
      live "/legal/terms", Legal.TermsLive, :index
      live "/legal/privacy", Legal.PrivacyLive, :index
    end

    live_session :onboarding,
      on_mount: [{AlgoraWeb.Analytics, :current_country}] do
      live "/onboarding/org", Onboarding.OrgLive
      live "/onboarding/dev", Onboarding.DevLive
      live "/pricing", PricingLive
      live "/pricing4", Pricing4Live
      live "/swift", SwiftBountiesLive
    end

    live_session :root,
      on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/auth/login", SignInLive, :login
      live "/auth/signup", SignInLive, :signup
    end

    live_session :wildcard,
      on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/:country_code", HomeLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", AlgoraWeb do
  #   pipe_through :api
  # end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:algora, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      scope "/" do
        if Application.compile_env(:algora, :require_admin_for_mailbox) do
          pipe_through :require_authenticated_admin
        end

        forward "/mailbox", Plug.Swoosh.MailboxPreview
      end
    end
  end
end
