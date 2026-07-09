defmodule CleanerCrmWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use CleanerCrmWeb, :html

  alias CleanerCrm.Accounts
  alias CleanerCrm.Users.Scope

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template, and it
  renders the role-aware app chrome.

  `variant` picks which chrome to render:

    * `:app` (default) — the drawer + sidebar shell for every
      authenticated surface under `/app`. Office roles (owner/admin)
      get the full grouped office nav in the sidebar; everyone else
      gets the cleaner's minimal "My Day" link. Reads `current_scope`
      to tell them apart.
    * `:portal` — the client portal's minimal Home/Invoices top bar.
      There's no user login in the portal, so this doesn't touch
      `current_scope` at all.
    * `:public` — a bare logo + "Client portal" top bar, for the
      landing page, the public booking funnel, and token-link pages
      that have no session to key a nav off of.

  ## Examples

      <Layouts.app flash={@flash} current_scope={@current_scope}>
        <h1>Content</h1>
      </Layouts.app>

      <Layouts.app flash={@flash} variant={:portal}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://phoenix.hexdocs.pm/scopes.html)"

  attr :variant, :atom,
    default: :app,
    values: [:app, :portal, :public],
    doc: "which chrome to render — see moduledoc above"

  slot :inner_block, required: true

  def app(%{variant: :app} = assigns) do
    role = nav_role(assigns[:current_scope])
    office? = role in [:owner, :admin]

    office_links = [
      {"Schedule", ~p"/app/schedule", "hero-calendar-days"},
      {"Clients", ~p"/app/clients", "hero-user-group"},
      {"Quotes", ~p"/app/quotes", "hero-document-currency-dollar"},
      {"Invoices", ~p"/app/invoices", "hero-receipt-percent"},
      {"Timesheets", ~p"/app/timesheets", "hero-clock"},
      {"Quality", ~p"/app/quality", "hero-check-badge"},
      {"Reviews", ~p"/app/reviews", "hero-star"},
      {"Reminders", ~p"/app/reminders", "hero-bell-alert"},
      {"Audit", ~p"/app/audit", "hero-clipboard-document-list"}
    ]

    user_settings_link = {"User settings", ~p"/app/users/settings", "hero-cog-6-tooth"}

    office_settings_links = [
      {"Rate card", ~p"/app/quotes/rate-card", "hero-currency-dollar"},
      {"Booking policy", ~p"/app/settings/booking", "hero-calendar"},
      {"Accounts", ~p"/app/accounts", "hero-building-office-2"},
      {"Integrations", ~p"/app/integrations", "hero-puzzle-piece"}
    ]

    settings_links =
      if office?, do: office_settings_links ++ [user_settings_link], else: [user_settings_link]

    assigns =
      assign(assigns,
        office?: office?,
        office_links: office_links,
        settings_links: settings_links
      )

    ~H"""
    <div class="drawer lg:drawer-open min-h-screen">
      <input id="app-drawer-toggle" type="checkbox" class="drawer-toggle" />

      <div class="drawer-content flex flex-col bg-base-100">
        <header class="navbar bg-base-200 border-b border-base-300 gap-2">
          <div class="flex-none lg:hidden">
            <label
              for="app-drawer-toggle"
              class="btn btn-square btn-ghost"
              aria-label="Open navigation"
            >
              <.icon name="hero-bars-3" class="size-5" />
            </label>
          </div>
          <div class="flex-1 px-2 lg:px-4 flex items-center gap-3">
            <div
              :if={@current_scope && @current_scope.active_account}
              class="breadcrumbs text-sm py-0"
              data-test="account-breadcrumb"
            >
              <ul>
                <li>
                  <.link
                    navigate={~p"/app/accounts/picker"}
                    class="link link-hover inline-flex items-center gap-1"
                    title="Switch account"
                  >
                    <.icon name="hero-building-office-2" class="size-4 opacity-70" />
                    {@current_scope.active_account.name}
                  </.link>
                </li>
              </ul>
            </div>
          </div>
          <div class="flex-none px-2">
            <.theme_toggle />
          </div>
        </header>

        <main class="flex-1 px-4 py-8 sm:px-6 lg:px-8">
          <div class="mx-auto max-w-5xl space-y-6">
            {render_slot(@inner_block)}
          </div>
        </main>
      </div>

      <div class="drawer-side z-20">
        <label for="app-drawer-toggle" aria-label="close navigation" class="drawer-overlay"></label>
        <aside class="w-64 min-h-full bg-base-200 border-r border-base-300 flex flex-col">
          <div class="p-6 border-b border-base-300">
            <a href="/" class="flex w-fit items-center gap-2">
              <img src={~p"/images/logo.svg"} width="28" />
              <span class="font-bold tracking-tight">Cleaner CRM</span>
            </a>
          </div>

          <ul class="menu p-4 text-base-content flex-1">
            <li :for={{label, path, icon} <- @office_links} :if={@office?} data-test="office-nav">
              <.link navigate={path}>
                <.icon name={icon} class="size-4" /> {label}
              </.link>
            </li>

            <li :if={@office?} class="mt-2 border-t border-base-300 pt-2">
              <.link navigate={~p"/app/field"}>
                <.icon name="hero-truck" class="size-4" /> Field view
              </.link>
            </li>

            <li :if={!@office?}>
              <.link navigate={~p"/app/field"} data-test="cleaner-nav">
                <.icon name="hero-sun" class="size-4" /> My Day
              </.link>
            </li>

            <li class="mt-2 border-t border-base-300 pt-2">
              <span class="menu-title px-1">Settings</span>
              <ul>
                <li :for={{label, path, icon} <- @settings_links}>
                  <.link navigate={path}>
                    <.icon name={icon} class="size-4" /> {label}
                  </.link>
                </li>
              </ul>
            </li>
          </ul>

          <div
            :if={@current_scope && @current_scope.user}
            class="p-4 border-t border-base-300 flex flex-col gap-2"
          >
            <div class="text-xs opacity-60 px-1 truncate" title={@current_scope.user.email}>
              {@current_scope.user.email}
            </div>
            <.link
              href={~p"/users/log-out"}
              method="delete"
              class="btn btn-ghost btn-sm justify-start"
            >
              <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Log out
            </.link>
          </div>
        </aside>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  def app(%{variant: :portal} = assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 gap-2">
      <div class="flex-1 min-w-0">
        <.link navigate={~p"/portal"} class="flex w-fit items-center gap-2 min-w-0">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="hidden sm:inline text-sm font-semibold truncate">Cleaner CRM</span>
        </.link>
      </div>

      <div data-test="portal-nav" class="flex items-center gap-1 sm:gap-3">
        <span class="hidden sm:inline text-sm font-medium opacity-60">Client Portal</span>
        <.link navigate={~p"/portal"} class="btn btn-ghost btn-sm">Home</.link>
        <.link navigate={~p"/portal/invoices"} class="btn btn-ghost btn-sm">Invoices</.link>
      </div>

      <div class="flex-none flex items-center gap-2">
        <.theme_toggle />
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  def app(%{variant: :public} = assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 gap-2">
      <div class="flex-1 min-w-0">
        <.link navigate={~p"/"} class="flex w-fit items-center gap-2 min-w-0">
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="hidden sm:inline text-sm font-semibold truncate">Cleaner CRM</span>
        </.link>
      </div>

      <.link navigate={~p"/portal"} data-test="public-nav" class="btn btn-ghost btn-sm">
        Client portal
      </.link>

      <div class="flex-none flex items-center gap-2">
        <.theme_toggle />
      </div>
    </header>

    <main class="px-4 py-20 sm:px-6 lg:px-8">
      <div class="mx-auto max-w-2xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  The office/admin/member role for `current_scope` on its active
  account, or `nil` when signed out, accountless, or (defensively)
  on any authorization error — a layout has no business crashing a
  page render over a nav decision.
  """
  def nav_role(%Scope{user: %{}, active_account_id: account_id} = scope)
      when is_binary(account_id) do
    try do
      Accounts.get_user_role(scope, scope.user.id, account_id)
    rescue
      _ -> nil
    end
  end

  def nav_role(_scope), do: nil

  @doc """
  Where a signed-in `current_scope` lands on "go to app": `/app/schedule`
  for office roles, `/app/field` for cleaners, `/app/accounts/new` for a
  fresh signup with no company yet, or `nil` when signed out.
  """
  def signed_in_home(%Scope{user: %{}, active_account_id: nil}), do: ~p"/app/accounts/new"

  def signed_in_home(%Scope{user: %{}} = scope) do
    if nav_role(scope) in [:owner, :admin], do: ~p"/app/schedule", else: ~p"/app/field"
  end

  def signed_in_home(_scope), do: nil

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={
          show(".phx-client-error #client-error")
          |> JS.remove_attribute("hidden", to: ".phx-client-error #client-error")
        }
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={
          show(".phx-server-error #server-error")
          |> JS.remove_attribute("hidden", to: ".phx-server-error #server-error")
        }
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 [[data-theme-source=system]_&]:!left-0 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
