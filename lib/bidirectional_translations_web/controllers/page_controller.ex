defmodule BidirectionalTranslationsWeb.PageController do
  use BidirectionalTranslationsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
