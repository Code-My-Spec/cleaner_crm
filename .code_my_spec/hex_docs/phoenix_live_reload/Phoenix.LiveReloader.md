# Phoenix.LiveReloader

Router for live-reload detection in development.

## Usage

Add the `Phoenix.LiveReloader` plug within a `code_reloading?` block
in your Endpoint, ie:

    if code_reloading? do
      socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
      plug Phoenix.CodeReloader
      plug Phoenix.LiveReloader
    end

## Configuration

All live-reloading configuration must be done inside the `:live_reload`
key of your endpoint, such as this:

    config :my_app, MyApp.Endpoint,
      ...
      live_reload: [
        patterns: [
          ~r{priv/static/.*(js|css|png|jpeg|jpg|gif)$},
          ~r{lib/my_app_web/views/.*(ex)$},
          ~r{lib/my_app_web/templates/.*(eex)$}
        ]
      ]

The following options are supported:

  * `:patterns` - a list of patterns to trigger the live reloading.
    This option is required to enable any live reloading.

  * `:notify` - a keyword list of topics pointing to a list of patterns.
    A message of the form `{:phoenix_live_reload, topic, path}` will be
    broadcast on the topic whenever file in the list of patterns changes.

  * `:debounce` - an integer in milliseconds to wait before sending
    live reload events to the browser. Defaults to `0`.

  * `:iframe_attrs` - attrs to be given to the iframe injected by
    live reload. Expects a keyword list of atom keys and string values.

  * `:target_window` - the window that will be reloaded, as an atom.
    Valid values are `:top` and `:parent`. Defaults to `:parent`.

  * `:url` - the URL of the live reload socket connection. By default
    it will use the browser's host and port.

  * `:suffix` - if you are running live-reloading on an umbrella app,
    you may want to give a different suffix to each socket connection.
    You can do so with the `:suffix` option:

        live_reload: [
          suffix: "/proxied/app/path"
        ]

    And then configure the endpoint to use the same suffix:

        if code_reloading? do
          socket "/phoenix/live_reload/socket/proxied/app/path", Phoenix.LiveReloader.Socket
          ...
        end

  * `:reload_page_on_css_changes` - If true, CSS changes will trigger a full
    page reload like other asset types instead of the default hot reload.
    Useful when class names are determined at runtime, for example when
    working with CSS modules. Defaults to false.

  * `:web_console_logger` - If true, the live reloader will log messages
    to the web console in your browser. Defaults to false.
    *Note*: Requires Elixir v1.15+ and your application javascript bundle will need
    to enable logs. See the README for more information.

In an umbrella app, if you want to enable live reloading based on code
changes in sibling applications, set the `reloadable_apps` option on your
endpoint to ensure the code will be recompiled, then add the dirs to
`:phoenix_live_reload` to trigger page reloads:

    # in config/dev.exs
    root_path =
      __ENV__.file
      |> Path.dirname()
      |> Path.join("..")
      |> Path.expand()

    config :phoenix_live_reload, :dirs, [
      Path.join([root_path, "apps", "app1"]),
      Path.join([root_path, "apps", "app2"]),
    ]

You'll also want to be sure that the configured `:patterns` for
`live_reload` will match files in the sibling application.