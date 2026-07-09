defmodule CleanerCrmWeb.CacheBodyReader do
  @moduledoc """
  Custom `Plug.Parsers` body reader that additionally stashes the exact
  raw bytes of the Stripe webhook request into `conn.assigns[:raw_body]`.
  Stripe's webhook signature is computed over those exact bytes, which
  vanish once `Plug.Parsers` decodes them into `conn.params` — every
  other request is read exactly as `Plug.Conn.read_body/2` would read
  it, unchanged.
  """

  @webhook_path "/webhooks/stripe"

  def read_body(%Plug.Conn{request_path: @webhook_path} = conn, opts) do
    with {:ok, body, conn} <- Plug.Conn.read_body(conn, opts) do
      {:ok, body, Plug.Conn.assign(conn, :raw_body, body)}
    end
  end

  def read_body(conn, opts), do: Plug.Conn.read_body(conn, opts)
end
