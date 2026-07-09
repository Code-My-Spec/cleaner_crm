# Phoenix.Ecto.SQL.Sandbox

A plug to allow concurrent, transactional acceptance tests with
[`Ecto.Adapters.SQL.Sandbox`](https://hexdocs.pm/ecto_sql/Ecto.Adapters.SQL.Sandbox.html).

## Example

This plug should only be used during tests. First, set a flag to
enable it in `config/test.exs`:

    config :your_app, sql_sandbox: true

And use the flag to conditionally add the plug to `lib/your_app/endpoint.ex`:

    if Application.compile_env(:your_app, :sql_sandbox) do
      plug Phoenix.Ecto.SQL.Sandbox
    end

It's important that this is at the top of `endpoint.ex`, before any other plugs.

Then, within an acceptance test, checkout a sandboxed connection as before.
Use `metadata_for/2` helper to get the session metadata to that will allow access
to the test's connection. In general lines, you would write this:

    setup tags do
      pid = Ecto.Adapters.SQL.Sandbox.start_owner!(YourApp.Repo, shared: not tags[:async])
      on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
      metadata_header = Phoenix.Ecto.SQL.Sandbox.metadata_for(YourApp.Repo, pid)
      # pass the metadata to the acceptance test library
      :ok
    end

You can follow the instructions for Wallaby [here](https://hexdocs.pm/wallaby/readme.html#phoenix).

## Acceptance tests with channels

To support channels, in addition the above, you need to make it so each channel
is allowed within the sandbox. The first step is to access the relevant header
metadata.

To do so, you must declare that you want to pass connection information to your
socket. This is typically the user agent header, but it can be a custom x-header
too:

    socket "/path", Socket,
      websocket: [connect_info: [:user_agent, …]]

    socket "/path", Socket,
      websocket: [connect_info: [:x_headers, …]]

Now use the `c:Phoenix.Socket.connect/3` callback to access the header and
store it in the socket:

    # user_socket.ex
    def connect(_params, socket, connect_info) do
      {:ok, assign(socket, :phoenix_ecto_sandbox, connect_info.user_agent)}
    end

Or if you are using a custom header:

    Enum.find_value(connect_info.x_headers, fn
      {"x-my-custom-header", val} -> val
      _ -> nil
    end)

This stores the value on the socket, so it can be available to all of your
channels for allowing the sandbox.

    # room_channel.ex
    def join("room:lobby", _payload, socket) do
      allow_ecto_sandbox(socket)
      {:ok, socket}
    end

    # This is a great function to extract to a helper module
    defp allow_ecto_sandbox(socket) do
      Phoenix.Ecto.SQL.Sandbox.allow(
        socket.assigns.phoenix_ecto_sandbox,
        Ecto.Adapters.SQL.Sandbox
      )
    end

`allow/2` needs to be manually called once for each channel, at best directly
at the start of `c:Phoenix.Channel.join/3`.

## Acceptance tests with LiveViews

LiveViews can be supported in a similar fashion to channels. First declare the
`:user_agent` (or a custom header) in your live socket configuration in `endpoint.ex`:

    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [:user_agent, session: @session_options]]

Now you can use the `on_mount/4` callback to check the header and assign the sandbox:

    defmodule MyApp.LiveAcceptance do
      import Phoenix.LiveView
      import Phoenix.Component

      def on_mount(:default, _params, _session, socket) do
        socket =
          assign_new(socket, :phoenix_ecto_sandbox, fn ->
            if connected?(socket), do: get_connect_info(socket, :user_agent)
          end)

        metadata = socket.assigns.phoenix_ecto_sandbox
        Phoenix.Ecto.SQL.Sandbox.allow(metadata, Ecto.Adapters.SQL.Sandbox)
        {:cont, socket}
      end
    end

Now, in your `my_app_web.ex` file, you can invoke this callback for all of your
LiveViews if the sandbox configuration, defined at the beginning of the
documentation, is enabled:

    def live_view do
      quote do
        use Phoenix.LiveView
        # ...

        if Application.compile_env(:your_app, :sql_sandbox) do
          on_mount MyApp.LiveAcceptance
        end

        # ...
      end
    end

If you have `on_mount` hooks in `live_session` defined in your `router.ex`
(for example, routes requiring authentication after running `mix phx.gen.auth`
to generate your authentication system), make sure the `MyApp.LiveAcceptance`
hook runs before, so following hooks have access to the Ecto Sandbox:

    live_session :require_authenticated_user,
      on_mount:
        if(Application.compile_env(:your_app, :sql_sandbox),
          do: [MyAppWeb.AcceptanceHook],
          else: []
        ) ++ [{MyAppWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end

## Concurrent end-to-end tests with external clients

Concurrent and transactional tests for external HTTP clients is supported,
allowing for complete end-to-end tests. This is useful for cases such as
JavaScript test suites for single page applications that exercise the
Phoenix endpoint for end-to-end test setup and teardown. To enable this,
you can expose a sandbox route on the `Phoenix.Ecto.SQL.Sandbox` plug by
providing the `:at`, and `:repo` options. For example:

    plug Phoenix.Ecto.SQL.Sandbox,
      at: "/sandbox",
      repo: MyApp.Repo,
      timeout: 15_000 # the default

This would expose a route at `"/sandbox"` for the given repo where
external clients send POST requests to spawn a new sandbox session,
and DELETE requests to stop an active sandbox session. By default,
the external client is expected to pass up the `"user-agent"` header
containing serialized sandbox metadata returned from the POST request,
but this value may customized with the `:header` option.

Finally, make sure your repository mode is set either to `:manual`
or `{:shared, self()}` before the external client starts. This is
typically done by default in your `test/test_helper.exs`, but you
may need to do it explicitly depending on your setup:

    Ecto.Adapters.SQL.Sandbox.mode(MyApp.Repo, :manual)

## start_child/2

Spawns a sandbox session to checkout a connection for a remote client.

## Examples

    iex> {:ok, _owner_pid, metadata} = start_child(MyApp.Repo)

## stop/1

Stops a sandbox session holding a connection for a remote client.

## Examples

    iex> {:ok, owner_pid, metadata} = start_child(MyApp.Repo)
    iex> :ok = stop(owner_pid)

## metadata_for/3

Returns metadata to establish a sandbox for.

The metadata is then passed via user-agent/headers to browsers.
Upon request, the `Phoenix.Ecto.SQL.Sandbox` plug will decode
the header and allow the request process under the sandbox.

## Options

  * `:trap_exit` - if the browser being used for integration
    testing navigates away from a page or aborts a AJAX request
    while the request process is talking to the database, it
    will corrupt the database connection and make the test fail.
    Therefore, to avoid intermittent tests, we recommend trapping
    exits in the request process, so all database connections shut
    down cleanly. You can disable this behaviour by setting the
    option to false.

## encode_metadata/1

Encodes metadata generated by `metadata_for/2` for client response.

## decode_metadata/1

Decodes encoded metadata back into map generated from `metadata_for/2`.

## allow/2

Decodes the given metadata and allows the current process
under the given sandbox.