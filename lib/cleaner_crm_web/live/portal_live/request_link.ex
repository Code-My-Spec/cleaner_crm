defmodule CleanerCrmWeb.PortalLive.RequestLink do
  @moduledoc """
  "Get portal access" — the self-service stop for a client who lost
  or never got their magic link: the landing page's "Client portal"
  CTA always points at `/portal`, and `CleanerCrmWeb.PortalAuth`
  redirects an unauthenticated visit here instead of dead-ending, so
  this is every such client's actual first stop.

  Route: `/portal/request-link` — public, no session required.

  ## Dependencies

  - `CleanerCrm.Portal`
  """

  use CleanerCrmWeb, :live_view

  alias CleanerCrm.Portal

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} variant={:portal}>
      <.header>Get portal access</.header>

      <p class="text-base-content/70">
        Enter the email on file with your cleaning service and we'll send you a link to your client portal.
      </p>

      <.form
        :let={f}
        for={@form}
        id="request_link_form"
        phx-submit="submit"
        data-test="request-link-form"
      >
        <.input
          field={f[:email]}
          type="email"
          label="Email"
          autocomplete="email"
          spellcheck="false"
          required
          phx-mounted={JS.focus()}
        />
        <.button class="btn btn-primary w-full">Email me a portal link</.button>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Get portal access")
     |> assign(:form, to_form(%{"email" => nil}, as: "request_link"))}
  end

  @impl true
  def handle_event("submit", %{"request_link" => %{"email" => email}}, socket) do
    Portal.request_login_link(email)

    {:noreply,
     socket
     |> put_flash(:info, "If your email is in our system, you will receive a link shortly.")
     |> push_navigate(to: ~p"/portal/request-link")}
  end
end
