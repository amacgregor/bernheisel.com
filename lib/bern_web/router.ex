defmodule BernWeb.Router do
  use BernWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {BernWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :robots do
    plug :accepts, ["xml", "json", "webmanifest"]
  end

  scope "/", BernWeb, log: false do
    pipe_through [:robots]

    get "/sitemap.xml", SitemapController, :index
    get "/robots.txt", RobotController, :robots
    get "/rss.xml", RobotController, :rss
    get "/site.webmanifest", RobotController, :site_webmanifest
    get "/browserconfig.xml", RobotController, :browserconfig
  end

  scope "/", BernWeb do
    pipe_through :browser

    live "/", Live.Page, :show
    get "/blog/:id", BlogController, :show
    get "/blog", BlogController, :index
    live "/about", Live.Page, :show, as: :about, session: %{"page" => "about"}
    live "/projects", Live.Page, :show, as: :projects, session: %{"page" => "projects"}
  end

  scope "/admin" do
    pipe_through :browser
    live_dashboard "/dashboard", metrics: BernWeb.Telemetry
  end
end