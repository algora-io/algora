defmodule AlgoraWeb.Router do
  use AlgoraWeb, :router

  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2, require_authenticated_admin: 2]
  import AlgoraWeb.VisitorCountry, only: [fetch_current_country: 2]
  import Phoenix.LiveDashboard.Router, only: [live_dashboard: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_user
    plug :fetch_current_country
    plug :put_root_layout, {AlgoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser]

    get "/", RootController, :index

    get "/set_context/:context", ContextController, :set
    get "/a/:table_prefix/:activity_id", ActivityController, :get

    get "/callbacks/stripe/refresh", StripeCallbackController, :refresh
    get "/callbacks/stripe/return", StripeCallbackController, :return
    get "/callbacks/:provider/oauth", OAuthCallbackController, :new
    get "/callbacks/:provider/installation", InstallationCallbackController, :new
    get "/auth/logout", OAuthCallbackController, :sign_out

    get "/tip", TipController, :create

    scope "/admin" do
      live_session :admin,
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [{AlgoraWeb.UserAuth, :ensure_admin}, AlgoraWeb.User.Nav] do
        live "/analytics", Admin.CompanyAnalyticsLive
        live "/leaderboard", Admin.LeaderboardLive
      end

      live_dashboard "/dashboard",
        metrics: AlgoraWeb.Telemetry,
        additional_pages: [oban: Oban.LiveDashboard],
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [{AlgoraWeb.UserAuth, :ensure_admin}, AlgoraWeb.User.Nav]
    end

    live_session :public,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.User.Nav] do
      live "/bounties", BountiesLive, :index
      live "/community", CommunityLive, :index
      live "/leaderboard", LeaderboardLive, :index
      live "/projects", OrgsLive, :index
    end

    live_session :authenticated,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_authenticated}, AlgoraWeb.User.Nav] do
      live "/home", User.DashboardLive, :index
      live "/user/transactions", User.TransactionsLive, :index
      live "/user/settings", User.SettingsLive, :edit
      live "/user/installations", User.InstallationsLive, :index
    end

    live_session :org,
      layout: {AlgoraWeb.Layouts, :org},
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Org.Nav] do
      live "/org/:org_handle", Org.DashboardLive, :index
      live "/org/:org_handle/home", Org.DashboardPublicLive, :index
      live "/org/:org_handle/bounties", Org.BountiesLive, :index
      live "/org/:org_handle/contracts/:id", Contract.ViewLive
      live "/org/:org_handle/team", Org.TeamLive, :index
      live "/org/:org_handle/leaderboard", Org.LeaderboardLive, :index
    end

    live_session :org_admin,
      layout: {AlgoraWeb.Layouts, :org},
      on_mount: [
        {AlgoraWeb.UserAuth, :ensure_authenticated},
        {AlgoraWeb.UserAuth, :current_user},
        AlgoraWeb.Org.Nav,
        {AlgoraWeb.OrgAuth, :ensure_admin}
      ] do
      live "/org/:org_handle/settings", Org.SettingsLive, :edit
      live "/org/:org_handle/transactions", Org.TransactionsLive, :index
    end

    live_session :default, on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/auth/login", SignInLive, :index
      live "/payment/success", Payment.SuccessLive, :index
      live "/payment/canceled", Payment.CanceledLive, :index
      live "/@/:handle", User.ProfileLive, :index
      live "/claims/:group_id", ClaimLive
    end

    live_session :onboarding,
      on_mount: [{AlgoraWeb.VisitorCountry, :current_country}] do
      live "/onboarding/org", Onboarding.OrgLive
      live "/onboarding/dev", Onboarding.DevLive
      live "/pricing", PricingLive
    end

    live "/open-source", OpenSourceLive, :index

    live_session :root,
      on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/swift", SwiftBountiesLive
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
