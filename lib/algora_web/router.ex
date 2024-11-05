defmodule AlgoraWeb.Router do
  use AlgoraWeb, :router

  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_user
    plug :put_root_layout, {AlgoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/callbacks", AlgoraWeb do
    pipe_through :api

    post "/:provider/webhook", WebhookCallbackController, :new
  end

  scope "/callbacks", AlgoraWeb do
    pipe_through :browser

    get "/:provider/oauth", OAuthCallbackController, :new
    get "/:provider/installation", InstallationCallbackController, :new
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser]

    get "/", RootController, :index
    get "/set_context/:context", ContextController, :set

    get "/auth/logout", OAuthCallbackController, :sign_out
    delete "/auth/logout", OAuthCallbackController, :sign_out

    live_session :authenticated,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_authenticated}, AlgoraWeb.User.Nav] do
      live "/dashboard", User.DashboardLive, :index
      live "/user/settings", User.SettingsLive, :edit
      live "/user/installations", User.InstallationsLive, :index

      live "/@/:handle", User.ProfileLive, :index
    end

    live_session :org,
      layout: {AlgoraWeb.Layouts, :org},
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Org.Nav] do
      live "/org/:org_handle", Org.HomeLive, :index
      live "/org/:org_handle/dashboard", Org.DashboardLive, :index
      live "/org/:org_handle/bounties", Org.BountiesLive, :index
      live "/org/:org_handle/projects", Project.IndexLive, :index
      # live "/org/:org_handle/projects/:id", Project.ViewLive
      live "/org/:org_handle/jobs", Org.JobsLive, :index
      live "/org/:org_handle/analytics", Org.AnalyticsLive, :index
    end

    live_session :org2,
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Org.Nav] do
      live "/org/:org_handle/projects/:id", DevLive
    end

    live_session :default, on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/auth/login", SignInLive, :index
    end

    live "/orgs/new", Org.CreateLive

    live "/projects/new", Project.CreateLive
    live "/projects", Project.IndexLive
    live "/projects/:id", Project.ViewLive

    live "/jobs/new", Job.CreateLive
    live "/jobs", Job.IndexLive
    live "/jobs/:id", Job.ViewLive

    live "/leaderboard", LeaderboardLive

    live "/onboarding/org", Onboarding.OrgLive
    live "/onboarding/dev", Onboarding.DevLive
    live "/companies", CompaniesLive, :index
    live "/developers", DevelopersLive, :index

    live "/pricing", PricingLive

    live_session :root,
      on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/:country_code", HomeLive, :index
    end

    live "/open-source", OpenSourceLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AlgoraWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:algora, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AlgoraWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
