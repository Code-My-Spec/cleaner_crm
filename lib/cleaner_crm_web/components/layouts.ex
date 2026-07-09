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
  renders the role-aware app chrome: header, nav, and flash group.

  `variant` picks which header chrome to render:

    * `:app` (default) — the full role-aware nav for every
      authenticated surface. Office roles (owner/admin) get the
      grouped office nav; everyone else gets the cleaner's minimal
      "My Day" link. Reads `current_scope` to tell them apart.
    * `:portal` — the client portal's minimal Home/Invoices nav.
      There's no user login in the portal, so this doesn't touch
      `current_scope` at all.
    * `:public` — a bare logo + "Client portal" link, for the
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
    doc: "which header chrome to render — see moduledoc above"

  slot :inner_block, required: true

  def app(assigns) do
    role = nav_role(assigns[:current_scope])
    office? = role in [:owner, :admin]
    signed_in? = match?(%{user: %{}}, assigns[:current_scope])

    office_primary = [
      {"Schedule", ~p"/schedule"},
      {"Clients", ~p"/clients"},
      {"Quotes", ~p"/quotes"},
      {"Invoices", ~p"/invoices"},
      {"Timesheets", ~p"/timesheets"},
      {"Quality", ~p"/quality"},
      {"Reviews", ~p"/reviews"}
    ]

    office_more = [{"Reminders", ~p"/reminders"}, {"Audit", ~p"/audit"}]

    office_settings = [
      {"Rate card", ~p"/quotes/rate-card"},
      {"Booking policy", ~p"/settings/booking"},
      {"Accounts", ~p"/accounts"},
      {"Integrations", ~p"/integrations"},
      {"User settings", ~p"/users/settings"}
    ]

    assigns =
      assign(assigns,
        nav_role: role,
        office?: office?,
        signed_in?: signed_in?,
        office_primary: office_primary,
        office_more: office_more,
        office_settings: office_settings,
        office_mobile:
          office_primary ++ [{"Field view", ~p"/field"}] ++ office_more ++ office_settings
      )

    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 gap-2">
      <div class="flex-1 min-w-0">
        <.link
          navigate={brand_href(@variant, @current_scope, @nav_role)}
          class="flex w-fit items-center gap-2 min-w-0"
        >
          <img src={~p"/images/logo.svg"} width="36" />
          <span class="hidden sm:inline text-sm font-semibold truncate">Cleaner CRM</span>
        </.link>
      </div>

      <nav
        :if={@variant == :app and @office?}
        data-test="office-nav"
        class="hidden lg:flex items-center gap-1"
      >
        <.link :for={{label, path} <- @office_primary} navigate={path} class="btn btn-ghost btn-sm">
          {label}
        </.link>

        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-1">
            More <.icon name="hero-chevron-down-micro" class="size-3" />
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-10 mt-3 w-40 p-2 shadow"
          >
            <li :for={{label, path} <- @office_more}><.link navigate={path}>{label}</.link></li>
          </ul>
        </div>

        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="btn btn-ghost btn-sm gap-1">
            Settings <.icon name="hero-chevron-down-micro" class="size-3" />
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-10 mt-3 w-48 p-2 shadow"
          >
            <li :for={{label, path} <- @office_settings}><.link navigate={path}>{label}</.link></li>
          </ul>
        </div>

        <.link navigate={~p"/field"} class="btn btn-ghost btn-sm">Field view</.link>
      </nav>

      <.link
        :if={@variant == :app and @signed_in? and not @office?}
        navigate={~p"/field"}
        data-test="cleaner-nav"
        class="btn btn-ghost btn-sm"
      >
        My Day
      </.link>

      <div :if={@variant == :portal} data-test="portal-nav" class="flex items-center gap-1 sm:gap-3">
        <span class="hidden sm:inline text-sm font-medium opacity-60">Client Portal</span>
        <.link navigate={~p"/portal"} class="btn btn-ghost btn-sm">Home</.link>
        <.link navigate={~p"/portal/invoices"} class="btn btn-ghost btn-sm">Invoices</.link>
      </div>

      <.link
        :if={@variant == :public}
        navigate={~p"/portal"}
        data-test="public-nav"
        class="btn btn-ghost btn-sm"
      >
        Client portal
      </.link>

      <div class="flex-none flex items-center gap-2">
        <.theme_toggle />

        <div :if={@variant == :app and @signed_in?} class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="btn btn-ghost btn-square" aria-label="User menu">
            <.icon name="hero-user-circle-mini" class="size-6" />
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-10 mt-3 w-56 p-2 shadow"
          >
            <li class="menu-title truncate">{@current_scope.user.email}</li>
            <li><.link navigate={~p"/users/settings"}>Settings</.link></li>
            <li><.link href={~p"/users/log-out"} method="delete">Log out</.link></li>
          </ul>
        </div>

        <div :if={@variant == :app and @office?} class="dropdown dropdown-end lg:hidden">
          <div tabindex="0" role="button" class="btn btn-ghost btn-square" aria-label="More links">
            <.icon name="hero-bars-3" class="size-5" />
          </div>
          <ul
            tabindex="0"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-10 mt-3 w-56 p-2 shadow"
          >
            <li :for={{label, path} <- @office_mobile}><.link navigate={path}>{label}</.link></li>
          </ul>
        </div>
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
  Where a signed-in `current_scope` lands on "go to app": `/schedule`
  for office roles, `/field` for cleaners, `/accounts/new` for a
  fresh signup with no company yet, or `nil` when signed out.
  """
  def signed_in_home(%Scope{user: %{}, active_account_id: nil}), do: ~p"/accounts/new"

  def signed_in_home(%Scope{user: %{}} = scope) do
    if nav_role(scope) in [:owner, :admin], do: ~p"/schedule", else: ~p"/field"
  end

  def signed_in_home(_scope), do: nil

  defp brand_href(:portal, _scope, _role), do: ~p"/portal"
  defp brand_href(:public, _scope, _role), do: ~p"/"

  defp brand_href(:app, scope, role) do
    cond do
      role in [:owner, :admin] -> ~p"/schedule"
      match?(%{user: %{}}, scope) -> ~p"/field"
      true -> ~p"/"
    end
  end

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
