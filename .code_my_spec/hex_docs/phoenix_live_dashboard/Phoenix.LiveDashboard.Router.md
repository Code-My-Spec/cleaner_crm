# Phoenix.LiveDashboard.Router

Provides LiveView routing for LiveDashboard.

## live_dashboard/2

Defines a LiveDashboard route.

It expects the `path` the dashboard will be mounted at
and a set of options. You can then link to the route directly:

    <a href={~p"/dashboard"}>Dashboard</a>

## Options

  * `:live_socket_path` - Configures the socket path. it must match
    the `socket "/live", Phoenix.LiveView.Socket` in your endpoint.

  * `:csp_nonce_assign_key` - an assign key to find the CSP nonce
    value used for assets. Supports either `atom()` or a map of
    type `%{optional(:img) => atom(), optional(:script) => atom(), optional(:style) => atom()}`

  * `:ecto_repos` - the repositories to show database information.
    Currently only PostgreSQL, MySQL, and SQLite databases are supported.
    If you don't specify but your app is running Ecto, we will try to
    auto-discover the available repositories. You can disable this behavior
    by setting `[]` to this option.

  * `:env_keys` - Configures environment variables to display.
    It is defined as a list of string keys. If not set, the environment
    information will not be displayed

  * `:home_app` - A tuple with the app name and version to show on
    the home page. Defaults to `{"Dashboard", :phoenix_live_dashboard}`

  * `:metrics` - Configures the module to retrieve metrics from.
    It can be a `module` or a `{module, function}`. If nothing is
    given, the metrics functionality will be disabled. If `false` is
    passed, then the menu item won't be visible.

  * `:metrics_history` - Configures a callback for retrieving metric history.
    It must be an "MFA" tuple of  `{Module, :function, arguments}` such as
      metrics_history: {MyStorage, :metrics_history, []}
    If not set, metrics will start out empty/blank and only display
    data that occurs while the browser page is open.

  * `:on_mount` - Declares a custom list of `Phoenix.LiveView.on_mount/1`
    callbacks to add to the dashboard's `Phoenix.LiveView.Router.live_session/3`.
    A single value may also be declared.

  * `:request_logger` - By default the Request Logger page is enabled. Passing
     `false` will disable this page.

  * `:request_logger_cookie_domain` - Configures the domain the request_logger
    cookie will be written to. It can be a string or `:parent` atom.
    When a string is given, it will directly  set cookie domain to the given
    value. When `:parent` is given, it will take the parent domain from current
    endpoint host (if host is "www.acme.com" the cookie will be scoped on
    "acme.com"). When not set, the cookie will be scoped to current domain.

  * `:allow_destructive_actions` - When true, allow destructive actions directly
    from the UI. Defaults to `false`. The following destructive actions are
    available in the dashboard:

      * "Kill process" - a "Kill process" button on the process modal

    Note that custom pages given to "Additional pages" may support their own
    destructive actions.

  * `:additional_pages` - A keyword list of additional pages

## Examples

    defmodule MyAppWeb.Router do
      use Phoenix.Router
      import Phoenix.LiveDashboard.Router

      scope "/", MyAppWeb do
        pipe_through [:browser]
        live_dashboard "/dashboard",
          metrics: {MyAppWeb.Telemetry, :metrics},
          env_keys: ["APP_USER", "VERSION"],
          metrics_history: {MyStorage, :metrics_history, []},
          request_logger_cookie_domain: ".acme.com"
      end
    end