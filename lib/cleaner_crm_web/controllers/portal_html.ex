defmodule CleanerCrmWeb.PortalHTML do
  @moduledoc """
  Pages rendered by `CleanerCrmWeb.PortalController` — currently just
  the "link invalid or expired" page a client lands on with a bad or
  stale magic link.
  """

  use CleanerCrmWeb, :html

  embed_templates "portal_html/*"
end
