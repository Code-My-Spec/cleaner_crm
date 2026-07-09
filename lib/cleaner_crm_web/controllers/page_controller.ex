defmodule CleanerCrmWeb.PageController do
  use CleanerCrmWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
