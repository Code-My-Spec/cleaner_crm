# Phoenix.Endpoint.Cowboy2Adapter

The Cowboy2 adapter for Phoenix.

## Endpoint configuration

This adapter uses the following endpoint configuration:

  * `:http` - the configuration for the HTTP server. It accepts all options
    as defined by [`Plug.Cowboy`](https://plug-cowboy.hexdocs.pm/). Defaults
    to `false`

  * `:https` - the configuration for the HTTPS server. It accepts all options
    as defined by [`Plug.Cowboy`](https://plug-cowboy.hexdocs.pm/). Defaults
    to `false`

  * `:drainer` - a drainer process that triggers when your application is
    shutting down to wait for any on-going request to finish. It accepts all
    options as defined by [`Plug.Cowboy.Drainer`](https://plug-cowboy.hexdocs.pm/Plug.Cowboy.Drainer.html).
    Defaults to `[]`, which will start a drainer process for each configured endpoint,
    but can be disabled by setting it to `false`.

## Custom dispatch options

You can provide custom dispatch options in order to use Phoenix's
builtin Cowboy server with custom handlers. For example, to handle
raw WebSockets [as shown in Cowboy's docs](https://github.com/ninenines/cowboy/tree/master/examples)).

The options are passed to both `:http` and `:https` keys in the
endpoint configuration. However, once you pass your custom dispatch
options, you will need to manually wire the Phoenix endpoint by
adding the following rule:

    {:_, Plug.Cowboy.Handler, {MyAppWeb.Endpoint, []}}

For example:

    config :myapp, MyAppWeb.Endpoint,
      http: [dispatch: [
              {:_, [
                  {"/foo", MyAppWeb.CustomHandler, []},
                  {:_, Plug.Cowboy.Handler, {MyAppWeb.Endpoint, []}}
                ]}]]

It is also important to specify your handlers first, otherwise
Phoenix will intercept the requests before they get to your handler.