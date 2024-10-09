defmodule AlgoraWeb.Router do
  use AlgoraWeb, :router

  import AlgoraWeb.UserAuth, only: [fetch_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :fetch_current_user
    plug :put_root_layout, html: {AlgoraWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AlgoraWeb do
    pipe_through :browser

    get "/oauth/callbacks/:provider", OAuthCallbackController, :new
  end

  scope "/", AlgoraWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", AlgoraWeb do
    pipe_through :browser

    delete "/auth/logout", OAuthCallbackController, :sign_out
  end

  live_session :default, on_mount: [{AlgoraWeb.UserAuth, :current_user}, AlgoraWeb.Nav] do
    live "/auth/login", AlgoraWeb.SignInLive, :index
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
