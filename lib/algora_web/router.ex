defmodule AlgoraWeb.Router do
  use AlgoraWeb, :router

  import AlgoraWeb.Analytics, only: [fetch_current_country: 2, fetch_current_page: 2]
  import AlgoraWeb.RedirectPlug
  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2]
  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router, only: [live_dashboard: 2]

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
    plug :fetch_session
    plug Plug.Parsers, parsers: [:urlencoded, {:json, json_decoder: Jason}]
  end

  # Legacy tRPC pipeline
  pipeline :trpc do
    plug CORSPlug, headers: ["Content-Type"]
  end

  @redirects Application.compile_env(:algora, :redirects, [])

  for {from, to} <- @redirects do
    redirect(from, to, :temporary)
  end

  scope "/" do
    forward "/asset", AlgoraWeb.Plugs.RewriteAssetsPlug, upstream: :assets_url
    forward "/ingest/static", AlgoraWeb.Plugs.RewriteIngestStaticPlug, upstream: :ingest_static_url
    forward "/ingest", AlgoraWeb.Plugs.RewriteIngestPlug, upstream: :ingest_url
    forward "/observe/script.js", AlgoraWeb.Plugs.RewriteObserveJSPlug, upstream: "https://plausible.io/js/script.js"
    forward "/observe/event", AlgoraWeb.Plugs.RewriteObserveEventPlug, upstream: "https://plausible.io/api/event"
  end

  scope "/admin", AlgoraWeb do
    pipe_through [:browser]

    live_session :admin,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_admin}, AlgoraWeb.Admin.Nav] do
      live "/", Admin.AdminLive
      live "/leaderboard", Admin.LeaderboardLive
      live "/chat/:id", Chat.ThreadLive
      live "/campaign", Admin.CampaignLive
      live "/seed", Admin.SeedLive
      live "/devs", Admin.DevsLive
    end

    live_dashboard "/dashboard",
      metrics: AlgoraWeb.Telemetry,
      additional_pages: [],
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_admin}]

    oban_dashboard("/oban", resolver: AlgoraWeb.ObanDashboardResolver)
  end

  scope "/admin", AlgoraCloud do
    pipe_through [:browser]

    live_session :admin_cloud,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_admin}, AlgoraWeb.Admin.Nav] do
      case Code.ensure_compiled(AlgoraCloud.CrawlLive) do
        {:module, _} -> live "/crawl", CrawlLive
        _ -> nil
      end
    end
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser]

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

    live_session :authenticated,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :ensure_authenticated}, AlgoraWeb.User.Nav] do
      live "/home", User.DashboardLive, :index
      live "/user/transactions", User.TransactionsLive, :index
      live "/user/settings", User.SettingsLive, :edit
      live "/user/installations", User.InstallationsLive, :index
    end

    live_session :home, on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/", HomeLive
    end

    live_session :public,
      layout: {AlgoraWeb.Layouts, :user},
      on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.User.Nav] do
      live "/bounties", BountiesLive, :index
      live "/bounties/:tech", BountiesLive, :index
      live "/jobs", JobsLive, :index
      live "/leaderboard", LeaderboardLive, :index
      live "/projects", OrgsLive, :index
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
      live "/community", CommunityLive, :index
      live "/community/:tech", CommunityLive, :index
      live "/crowdfund", CrowdfundLive, :index
      live "/pricing", PricingLive
      live "/challenges", ChallengesLive
      live "/challenges/prettier", Challenges.PrettierLive
      live "/challenges/golem", Challenges.GolemLive
      live "/challenges/tsperf", Challenges.TsperfLive
      live "/swift", SwiftBountiesLive
      live "/blog/:slug", BlogLive, :show
      live "/blog", BlogLive, :index
      live "/changelog/:slug", ChangelogLive, :show
      live "/changelog", ChangelogLive, :index
      live "/docs/*path", DocsLive, :show
      live "/case-studies/:slug", CaseStudyLive, :show
      live "/case-studies", CaseStudyLive, :index
    end

    live_session :root,
      on_mount: [{AlgoraWeb.UserAuth, :current_user}] do
      live "/auth/login", SignInLive, :login
      live "/auth/signup", SignInLive, :signup
    end

    live "/0/bounties/:id", OG.BountyLive, :show
    get "/og/*path", OGImageController, :generate
  end

  scope "/api", AlgoraWeb.API do
    pipe_through :api
    post "/store_session", StoreSessionController, :create

    # Legacy tRPC endpoints
    scope "/trpc" do
      pipe_through :trpc

      options "/bounty.list", BountyController, :options
      get "/bounty.list", BountyController, :index
    end

    # Legacy OG Image redirects
    get "/og/:org_handle/:asset", OGRedirectController, :redirect_to_org_path

    # Shields.io badges
    get "/shields/:org_handle/bounties", ShieldsController, :bounties
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
        forward "/mailbox", Plug.Swoosh.MailboxPreview
      end
    end
  end

  scope "/", AlgoraWeb do
    pipe_through [:browser]

    scope "/:user_handle" do
      live_session :user,
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [{AlgoraWeb.UserAuth, :current_user}, {AlgoraWeb.User.Nav, :viewer}] do
        live "/profile", User.ProfileLive, :index
      end
    end

    scope "/:org_handle" do
      live_session :org,
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Org.Nav] do
        live "/dashboard", Org.DashboardLive, :index
        live "/home", Org.HomeLive, :index
        live "/bounties", Org.BountiesLive, :index
        live "/bounties/new", Org.BountiesNewLive, :index
        live "/bounties/community", Org.BountiesNewLive, :index
        live "/bounties/:id", BountyLive, :index
        # live "/contracts/:id", Contract.ViewLive
        live "/contracts/:id", ContractLive
        live "/team", Org.TeamLive, :index
        live "/leaderboard", Org.LeaderboardLive, :index
        live "/jobs", Org.JobsLive, :index
        live "/jobs/:id", Org.JobLive
        live "/jobs/:id/:tab", Org.JobLive
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

    scope "/:repo_owner/:repo_name" do
      get "/", RepoController, :index

      live_session :repo,
        layout: {AlgoraWeb.Layouts, :user},
        on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Org.RepoNav] do
        live "/issues/:number", BountyLive
        live "/pull/:number", BountyLive
      end
    end

    scope "/:handle" do
      get "/", UserController, :index
    end
  end
end
