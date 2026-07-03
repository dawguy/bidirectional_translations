defmodule BidirectionalTranslationsWeb.Router do
  use BidirectionalTranslationsWeb, :router

  import BidirectionalTranslationsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BidirectionalTranslationsWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BidirectionalTranslationsWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", BidirectionalTranslationsWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:bidirectional_translations, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BidirectionalTranslationsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BidirectionalTranslationsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{BidirectionalTranslationsWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/dashboard", DashboardLive, :index
      live "/articles", ArticleLive.Index, :index
      live "/articles/new", ArticleLive.Form, :new
      live "/articles/:id/edit", ArticleLive.Form, :edit
      live "/articles/:id", ArticleLive.Show, :show
      live "/sessions/:id/practice", SessionLive.Practice, :show
      live "/library", LibraryLive.Index, :index
      live "/library/new", LibraryLive.Form, :new
      live "/library/:id/edit", LibraryLive.Form, :edit
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", BidirectionalTranslationsWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{BidirectionalTranslationsWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
