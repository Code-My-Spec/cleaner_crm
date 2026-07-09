# Phoenix.LiveView



## __using__/1

Uses LiveView in the current module to mark it a LiveView.

    use Phoenix.LiveView,
      container: {:tr, class: "colorized"},
      layout: {MyAppWeb.Layouts, :app},
      log: :info

## Options

  * `:container` - an optional tuple for the HTML tag and DOM attributes to
    be used for the LiveView container. For example: `{:li, style: "color: blue;"}`.
    See `Phoenix.Component.live_render/3` for more information and examples.

  * `:global_prefixes` - the global prefixes to use for components. See
    `Global Attributes` in `Phoenix.Component` for more information.

  * `:layout` - configures the layout the LiveView will be rendered in.
    This layout can be overridden by on `c:mount/3` or via the `:layout`
    option in `Phoenix.LiveView.Router.live_session/2`

  * `:log` - configures the log level for the LiveView, either `false`
    or a log level

## __live__/1

Defines metadata for a LiveView.

This must be returned from the `__live__` callback.

It accepts:

  * `:container` - an optional tuple for the HTML tag and DOM attributes to
    be used for the LiveView container. For example: `{:li, style: "color: blue;"}`.

  * `:layout` - configures the layout the LiveView will be rendered in.
    This layout can be overridden by on `c:mount/3` or via the `:layout`
    option in `Phoenix.LiveView.Router.live_session/2`

  * `:log` - configures the log level for the LiveView, either `false`
    or a log level

  * `:on_mount` - a list of tuples with module names and arguments to be invoked
    as `on_mount` hooks

## on_mount/1

Declares a module callback to be invoked on the LiveView's mount.

The function within the given module, which must be named `on_mount`,
will be invoked before both disconnected and connected mounts. The hook
has the option to either halt or continue the mounting process as usual.
If you wish to redirect the LiveView, you **must** halt, otherwise an error
will be raised.

Tip: if you need to define multiple `on_mount` callbacks, avoid defining
multiple modules. Instead, pass a tuple and use pattern matching to handle
different cases:

    def on_mount(:admin, _params, _session, socket) do
      {:cont, socket}
    end

    def on_mount(:user, _params, _session, socket) do
      {:cont, socket}
    end

And then invoke it as:

    on_mount {MyAppWeb.SomeHook, :admin}
    on_mount {MyAppWeb.SomeHook, :user}

Registering `on_mount` hooks can be useful to perform authentication
as well as add custom behaviour to other callbacks via `attach_hook/4`.

The `on_mount` callback can return a keyword list of options as a third
element in the return tuple. These options are identical to what can
optionally be returned in `c:mount/3`.

## Examples

The following is an example of attaching a hook via
`Phoenix.LiveView.Router.live_session/3`:

    # lib/my_app_web/live/init_assigns.ex
    defmodule MyAppWeb.InitAssigns do
      @moduledoc """
      Ensures common `assigns` are applied to all LiveViews attaching this hook.
      """
      import Phoenix.LiveView
      import Phoenix.Component

      def on_mount(:default, _params, _session, socket) do
        {:cont, assign(socket, :page_title, "DemoWeb")}
      end

      def on_mount(:user, params, session, socket) do
        # code
      end

      def on_mount(:admin, _params, _session, socket) do
        {:cont, socket, layout: {DemoWeb.Layouts, :admin}}
      end
    end

    # lib/my_app_web/router.ex
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      # pipelines, plugs, etc.

      live_session :default, on_mount: MyAppWeb.InitAssigns do
        scope "/", MyAppWeb do
          pipe_through :browser
          live "/", PageLive, :index
        end
      end

      live_session :authenticated, on_mount: {MyAppWeb.InitAssigns, :user} do
        scope "/", MyAppWeb do
          pipe_through [:browser, :require_user]
          live "/profile", UserLive.Profile, :index
        end
      end

      live_session :admins, on_mount: {MyAppWeb.InitAssigns, :admin} do
        scope "/admin", MyAppWeb.Admin do
          pipe_through [:browser, :require_user, :require_admin]
          live "/", AdminLive.Index, :index
        end
      end
    end

## connected?/1

Returns true if the socket is connected.

Useful for checking the connectivity status when mounting the view.
For example, on initial page render, the view is mounted statically,
rendered, and the HTML is sent to the client. Once the client
connects to the server, a LiveView is then spawned and mounted
statefully within a process. Use `connected?/1` to conditionally
perform stateful work, such as subscribing to pubsub topics,
sending messages, etc.

## Examples

    defmodule DemoWeb.ClockLive do
      use Phoenix.LiveView
      ...
      def mount(_params, _session, socket) do
        if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

        {:ok, assign(socket, date: :calendar.local_time())}
      end

      def handle_info(:tick, socket) do
        {:noreply, assign(socket, date: :calendar.local_time())}
      end
    end

## put_private/3

Puts a new private key and value in the socket.

Privates are *not change tracked*. This storage is meant to be used by
users and libraries to hold state that doesn't require
change tracking. The keys should be prefixed with the app/library name.

## Examples

Key values can be placed in private:

    put_private(socket, :myapp_meta, %{foo: "bar"})

And then retrieved:

    socket.private[:myapp_meta]

## redirect/2

Annotates the socket for redirect to a destination path.

*Note*: LiveView redirects rely on instructing client
to perform a `window.location` update on the provided
redirect location. The whole page will be reloaded and
all state will be discarded.

Calling redirect shuts down the LiveView channel. If you need
to programmatically open an external link without causing the
LiveView to shut down, for example because of `mailto:` or `tel:`
URL schemes, consider using `push_event/3` with a custom client-side
handler instead.

## Options

  * `:to` - the path to redirect to. It must always be a local path
  * `:status` - the HTTP status code to use for the redirect. Defaults to 302.
  * `:external` - an external path to redirect to. Either a string
    or `{scheme, url}` to redirect to a custom scheme

## Examples

    {:noreply, redirect(socket, to: "/")}
    {:noreply, redirect(socket, to: "/", status: 301)}
    {:noreply, redirect(socket, external: "https://example.com")}

## push_patch/2

Annotates the socket for navigation within the current LiveView.

When navigating to the current LiveView, `c:handle_params/3` is
immediately invoked to handle the change of params and URL state.
Then the new state is pushed to the client, without reloading the
whole page while also maintaining the current scroll position.
For live navigation to another LiveView in the same `live_session`,
use `push_navigate/2`. Otherwise, use `redirect/2`.

## Options

  * `:to` - the required path to link to. It must always be a local path
  * `:replace` - the flag to replace the current history or push a new state.
    Defaults `false`.

## Examples

    {:noreply, push_patch(socket, to: "/")}
    {:noreply, push_patch(socket, to: "/", replace: true)}

## push_navigate/2

Annotates the socket for navigation to another LiveView in the same `live_session`.

The current LiveView will be shutdown and a new one will be mounted
in its place, without reloading the whole page. This can
also be used to remount the same LiveView, in case you want to start
fresh. If you want to navigate to the same LiveView without remounting
it, use `push_patch/2` instead.

## Options

  * `:to` - the required path to link to. It must always be a local path
  * `:replace` - the flag to replace the current history or push a new state.
    Defaults `false`.

## Examples

    {:noreply, push_navigate(socket, to: "/")}
    {:noreply, push_navigate(socket, to: "/", replace: true)}

## get_connect_params/1

Accesses the connect params sent by the client for use on connected mount.

Connect params are sent from the client on every connection and reconnection.
The parameters in the client can be computed dynamically, allowing you to pass
client state to the server. For example, you could use it to compute and pass
the user time zone from a JavaScript client:

```javascript
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: (_liveViewName) => {
    return {
      _csrf_token: csrfToken,
      time_zone: Intl.DateTimeFormat().resolvedOptions().timeZone
    }
  }
})
```

By computing the parameters with a function, reconnections will reevaluate
the code, allowing you to fetch the latest data.

On the LiveView, you will use `get_connect_params/1` to read the data,
which only remains available during mount. `nil` is returned when called
in a disconnected state and a `RuntimeError` is raised if called after
mount.

## Reserved params

The following params have special meaning in LiveView:

  * `"_csrf_token"` - the CSRF Token which must be explicitly set by the user
    when connecting
  * `"_mounts"` - the number of times the current LiveView is mounted.
    It is 0 on first mount, then increases on each reconnect. It resets
    when navigating away from the current LiveView or on errors
  * `"_track_static"` - set automatically with a list of all href/src from
    tags with the `phx-track-static` annotation in them. If there are no
    such tags, nothing is sent
  * `"_live_referer"` - sent by the client as the referer URL when a
    live navigation has occurred from `push_navigate` or client link navigate.

## Examples

    def mount(_params, _session, socket) do
      {:ok, assign(socket, width: get_connect_params(socket)["width"] || @width)}
    end

## get_connect_info/2

Accesses a given connect info key from the socket.

The following keys are supported: `:peer_data`, `:trace_context_headers`,
`:x_headers`, `:uri`, and `:user_agent`.

The connect information is available only during mount. During disconnected
render, all keys are available. On connected render, only the keys explicitly
declared in your socket are available. See `Phoenix.Endpoint.socket/3` for
a complete description of the keys.

## Examples

The first step is to declare the `connect_info` you want to receive.
Typically, it includes at least the session, but you must include all
other keys you want to access on connected mount, such as `:peer_data`:

    socket "/live", Phoenix.LiveView.Socket,
      websocket: [connect_info: [:peer_data, session: @session_options]]

Those values can now be accessed on the connected mount as
`get_connect_info/2`:

    def mount(_params, _session, socket) do
      peer_data = get_connect_info(socket, :peer_data)
      {:ok, assign(socket, ip: peer_data.address)}
    end

If the key is not available, usually because it was not specified
in `connect_info`, it returns nil.

## static_changed?/1

Returns true if the socket is connected and the tracked static assets have changed.

This function is useful to detect if the client is running on an outdated
version of the marked static files. It works by comparing the static paths
sent by the client with the one on the server.

**Note:** this functionality requires Phoenix v1.5.2 or later.

To use this functionality, the first step is to annotate which static files
you want to be tracked by LiveView, with the `phx-track-static`. For example:

```heex
<link phx-track-static rel="stylesheet" href={~p"/assets/app.css"} />
<script defer phx-track-static type="text/javascript" src={~p"/assets/app.js"}></script>
```

Now, whenever LiveView connects to the server, it will send a copy `src`
or `href` attributes of all tracked statics and compare those values with
the latest entries computed by `mix phx.digest` in the server.

The tracked statics on the client will match the ones on the server the
huge majority of times. However, if there is a new deployment, those values
may differ. You can use this function to detect those cases and show a
banner to the user, asking them to reload the page. To do so, first set the
assign on mount:

    def mount(params, session, socket) do
      {:ok, assign(socket, static_changed?: static_changed?(socket))}
    end

And then in your views:

```heex
<div :if={@static_changed?} id="reload-static">
  The app has been updated. Click here to <a href="#" onclick="window.location.reload()">reload</a>.
</div>
```

For larger projects, you can extract this into [a hook](`Phoenix.LiveView.on_mount/1`):

    # MyAppWeb.CheckStaticChanged
    def on_mount(:default, _params, _session, socket) do
      {:cont, assign(socket, static_changed?: static_changed?(socket))}
    end

And then add it to the existing `live_view` macro in your `my_app_web.ex` file or add it as part
of your `live_session` hooks.
If you prefer, you can also send a JavaScript script that immediately
reloads the page, but this will cause the client-side to lose all work in progress.

**Note:** only set `phx-track-static` on your own assets. For example, do
not set it in external JavaScript files:

```heex
<script defer phx-track-static type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js"></script>
```

Because you don't actually serve the file above, LiveView will interpret
the static above as missing, and this function will return true.

## send_update_after/4

Similar to `send_update/3` but the update will be delayed according to the given `time_in_milliseconds`.

It returns a reference which can be cancelled with `Process.cancel_timer/1`.

## Examples

    def handle_event("cancel-order", _, socket) do
      ...
      send_update_after(Cart, [id: "cart", status: "cancelled"], 3000)
      {:noreply, socket}
    end

    def handle_event("cancel-order-asynchronously", _, socket) do
      ...
      pid = self()

      Task.start(fn ->
        # Do something asynchronously
        send_update_after(pid, Cart, [id: "cart", status: "cancelled"], 3000)
      end)

      {:noreply, socket}
    end

## transport_pid/1

Returns the transport pid of the socket.

Raises `ArgumentError` if the socket is not connected.

## Examples

    iex> transport_pid(socket)
    #PID<0.107.0>

## stream/4

Detaches a hook with the given `name` from the lifecycle `stage`.

> ### Note {: .info}
> This function is for server-side lifecycle callbacks.
> For client-side hooks, see the
> [JS Interop guide](js-interop.md#client-hooks-via-phx-hook).

If no hook is found, this function is a no-op.

## Examples

    def handle_event(_, _, socket) do
      {:noreply, detach_hook(socket, :hook_that_was_attached, :handle_event)}
    end

## stream_insert/4

Inserts a new item or updates an existing item in the stream.

Returns an updated `socket`.

See `stream/4` for inserting multiple items at once.

The following options are supported:

  * `:at` - The index to insert or update the item in the collection on the client.
    By default, the item is appended to the parent DOM container. This is the same as
    passing a value of `-1`.
    If the item already exists in the parent DOM container then it will be
    updated in place.

  * `:limit` - A limit of items to maintain in the UI. A limit passed to `stream/4` does
    not affect subsequent calls to `stream_insert/4`, therefore the limit must be passed
    here as well in order to be enforced. See `stream/4` for more information on
    limiting streams.

  * `:update_only` - A boolean to only update the item in the stream. If the item does not
    exist on the client, it will not be inserted. Defaults to `false`.

## Examples

Imagine you define a stream on mount with a single item:

    stream(socket, :songs, [%Song{id: 1, title: "Song 1"}])

Then, in a callback such as `handle_info` or `handle_event`, you
can append a new song:

    stream_insert(socket, :songs, %Song{id: 2, title: "Song 2"})

Or prepend a new song with `at: 0`:

    stream_insert(socket, :songs, %Song{id: 2, title: "Song 2"}, at: 0)

Or update an existing song (in this case the `:at` option has no effect):

    stream_insert(socket, :songs, %Song{id: 1, title: "Song 1 updated"}, at: 0)

Or append a new song while limiting the stream to the last 10 items:

    stream_insert(socket, :songs, %Song{id: 2, title: "Song 2"}, limit: -10)

## Updating Items

As shown, an existing item on the client can be updated by issuing a `stream_insert`
for the existing item. When the client updates an existing item, the item will remain
in the same location as it was previously, and will not be moved to the end of the
parent children. To both update an existing item and move it to another position,
issue a `stream_delete`, followed by a `stream_insert`. For example:

    song = get_song!(id)

    socket
    |> stream_delete(:songs, song)
    |> stream_insert(:songs, song, at: -1)

See `stream_delete/3` for more information on deleting items.

## stream_delete/3

Deletes an item from the stream.

The item's DOM is computed from the `:dom_id` provided in the `stream/3` definition.
Delete information for this DOM id is sent to the client and the item's element
is removed from the DOM, following the same behavior of element removal, such as
invoking `phx-remove` commands and executing client hook `destroyed()` callbacks.

## Examples

    def handle_event("delete", %{"id" => id}, socket) do
      song = get_song!(id)
      {:noreply, stream_delete(socket, :songs, song)}
    end

See `stream_delete_by_dom_id/3` to remove an item without requiring the
original data structure.

Returns an updated `socket`.

## assign_async/4

Assigns keys asynchronously.

Wraps your function in a task linked to the caller, errors are wrapped.
Each key passed to `assign_async/3` will be assigned to
an `Phoenix.LiveView.AsyncResult` struct holding the status of the operation
and the result when the function completes.

The function must return either `{:ok, assigns}` or `{:error, reason}`,
where `assigns` is a map with the keys passed to `assign_async/3`.

The task is only started when the socket is connected.

## Options

  * `:supervisor` - allows you to specify a `Task.Supervisor` to supervise the task.
  * `:reset` - remove previous results during async operation when true. Possible values are
    `true`, `false`, or a list of keys to reset. Defaults to `false`.

## Examples

```elixir
def mount(%{"slug" => slug}, _, socket) do
  {:ok,
    socket
    |> assign(:foo, "bar")
    |> assign_async(:org, fn -> {:ok, %{org: fetch_org!(slug)}} end)
    |> assign_async([:profile, :rank], fn -> {:ok, %{profile: ..., rank: ...}} end)}
end
```

See [Async Operations](#module-async-operations) for more information.

## `assign_async/3` and `send_update/3`

Since the code inside `assign_async/3` runs in a separate process,
`send_update(Component, data)` does not work inside `assign_async/3`,
since `send_update/2` assumes it is running inside the LiveView process.
The solution is to explicitly send the update to the LiveView:

```elixir
parent = self()
assign_async(socket, :org, fn ->
  # ...
  send_update(parent, Component, data)
end)
```

## Testing async operations

When testing LiveViews and LiveComponents with async assigns, use
`Phoenix.LiveViewTest.render_async/2` to ensure the test waits until the async operations
are complete before proceeding with assertions or before ending the test. For example:

```elixir
{:ok, view, _html} = live(conn, "/my_live_view")
html = render_async(view)
assert html =~ "My assertion"
```

Not calling `render_async/2` to ensure all async assigns have finished might result in errors in
cases where your process has side effects:

```
[error] MyXQL.Connection (#PID<0.308.0>) disconnected: ** (DBConnection.ConnectionError) client #PID<0.794.0>
```

## start_async/4

Wraps your function in an asynchronous task and invokes a callback `name` to
handle the result.

The task is linked to the caller and errors/exits are wrapped.
The result of the task is sent to the `c:handle_async/3` callback
of the caller LiveView or LiveComponent.

If there is an in-flight task with the same `name`, the later `start_async` wins and the previous task’s result is ignored.
If you wish to replace an existing task, you can use `cancel_async/3` before `start_async/3`.
You are not restricted to just atoms for `name`, it can be any term such as a tuple.

The task is only started when the socket is connected.

## Options

  * `:supervisor` - allows you to specify a `Task.Supervisor` to supervise the task.

## Examples

    def mount(%{"id" => id}, _, socket) do
      {:ok,
       socket
       |> assign(:org, AsyncResult.loading())
       |> start_async(:my_task, fn -> fetch_org!(id) end)}
    end

    def handle_async(:my_task, {:ok, fetched_org}, socket) do
      %{org: org} = socket.assigns
      {:noreply, assign(socket, :org, AsyncResult.ok(org, fetched_org))}
    end

    def handle_async(:my_task, {:exit, reason}, socket) do
      %{org: org} = socket.assigns
      {:noreply, assign(socket, :org, AsyncResult.failed(org, {:exit, reason}))}
    end

See the moduledoc for more information.

## stream_async/4

Inserts data into a stream asynchronously.

Wraps your function in a task linked to the caller, errors are wrapped.
The key passed to `stream_async/3` will be used as the stream name. Furthermore,
a regular assign with the same name gets assigned a `Phoenix.LiveView.AsyncResult`
struct holding the status of the operation. The stream is initialized to an empty list
before starting the asynchronous function, so accessing `@streams.name` is always possible.

The function must return `{:ok, Enumerable.t()}` or `{:ok, Enumerable.t(), opts}`
where the opts are the same as in `stream/4`. The enumerable contains the values to be streamed.

If the function returns `{:error, any()}`, the `AsyncResult` is assigned as failed and
the stream is not updated.

The task is only started when the socket is connected.

## Options

  * `:supervisor` - allows you to specify a `Task.Supervisor` to supervise the task.
  * `:reset` - A boolean to control whether to remove previous results during the async operation.
    Defaults to `false`.

## Examples

    def mount(%{"slug" => slug}, _, socket) do
      current_scope = socket.assigns.current_scope

      {:ok,
        socket
        |> assign(:foo, "bar")
        |> assign_async(:org, fn -> {:ok, %{org: fetch_org!(current_scope)}} end)
        |> stream_async(:posts, fn -> {:ok, list_posts!(current_scope), limit: 10} end)
    end

Note the `reset` option controls the async assign, not the stream:

    def mount(_, _, socket) do
      {:ok,
        socket
        # IMPORTANT: reset here does NOT reset the stream, but only the loading state
        |> stream_async(:my_stream, fn -> {:ok, list_items!()} end, reset: true)
        # This resets the stream
        |> stream_async(:my_reset_stream, fn -> {:ok, list_items!(), reset: true} end)
    end

Any stream options need to be returned as optional third argument in the return value
of the asynchronous function.

## cancel_async/3

Cancels an async operation if one exists.

Accepts either the `%AsyncResult{}` when using `assign_async/3` or
the key passed to `start_async/3`.

The underlying process will be killed with the provided reason, or
with `{:shutdown, :cancel}` if no reason is passed. For `assign_async/3`
operations, the `:failed` field will be set to `{:exit, reason}`.
For `start_async/3`, the `c:handle_async/3` callback will receive
`{:exit, reason}` as the result.

Returns the `%Phoenix.LiveView.Socket{}`.

## Examples

    cancel_async(socket, :preview)
    cancel_async(socket, :preview, :my_reason)
    cancel_async(socket, socket.assigns.preview)