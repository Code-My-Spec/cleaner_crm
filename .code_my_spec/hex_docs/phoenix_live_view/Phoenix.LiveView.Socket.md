# Phoenix.LiveView.Socket

The LiveView socket for Phoenix Endpoints.

This is typically mounted directly in your endpoint.

    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [session: @session_options]]

To share an underlying transport connection between regular
Phoenix channels and LiveView processes, `use Phoenix.LiveView.Socket`
from your own `MyAppWeb.UserSocket` module.

Next, declare your `channel` definitions and optional `connect/3`, and
`id/1` callbacks to handle your channel specific needs, then mount
your own socket in your endpoint:

    socket "/live", MyAppWeb.UserSocket,
      websocket: [connect_info: [session: @session_options]]

If you require session options to be set at runtime, you can use
an MFA tuple. The function it designates must return a keyword list.

    socket "/live", MyAppWeb.UserSocket,
      websocket: [connect_info: [session: {__MODULE__, :runtime_opts, []}]]

    # ...

    def runtime_opts() do
      Keyword.put(@session_options, :domain, host())
    end