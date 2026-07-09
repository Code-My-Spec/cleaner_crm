# Phoenix.LiveView.Router

Provides LiveView routing for Phoenix routers.

## live_session/3

Defines a live session for live redirects within a group of live routes.

`live_session/3` allow routes defined with `live/4` to support
`navigate` redirects from the client with navigation purely over the existing
websocket connection. This allows live routes defined in the router to
mount a new root LiveView without additional HTTP requests to the server.
For backwards compatibility reasons, all live routes defined outside
of any live session are considered part of a single unnamed live session.

## Security Considerations

In a regular web application, we perform authentication and authorization
checks on every request. Given LiveViews start as a regular HTTP request,
they share the authentication logic with regular requests through plugs.
Once the user is authenticated, we typically validate the sessions on
the `mount` callback. Authorization rules generally happen on `mount`
(for instance, is the user allowed to see this page?) and also on
`handle_event` (is the user allowed to delete this item?). Performing
authorization on mount is important because `navigate`s *do not go
through the plug pipeline*.

`live_session` can be used to draw boundaries between groups of LiveViews.
Redirecting between `live_session`s will always force a full page reload
and establish a brand new LiveView connection. This is useful when LiveViews
require different authentication strategies or simply when they use different
root layouts (as the root layout is not updated between live redirects).

Please [read our guide on the security model](security-model.md) for a
detailed description and general tips on authentication, authorization,
and more.

> #### `live_session` and `forward` {: .warning}
>
> `live_session` does not currently work with `forward`. LiveView expects
> your `live` routes to always be directly defined within the main router
> of your application.

> #### `live_session` and `scope` {: .warning}
>
> Aliases set with `Phoenix.Router.scope/2` are not expanded in `live_session` arguments.
> You must use the full module name instead.

## Options

  * `:session` - An optional extra session map or MFA tuple to be merged with
    the LiveView session. For example, `%{"admin" => true}` or `{MyMod, :session, []}`.
    For MFA, the function is invoked and the `Plug.Conn` struct is prepended
    to the arguments list.

  * `:root_layout` - An optional root layout tuple for the initial HTTP render to
    override any existing root layout set in the router.

  * `:on_mount` - An optional list of hooks to attach to the mount lifecycle _of
    each LiveView in the session_. See `Phoenix.LiveView.on_mount/1`. Passing a
    single value is also accepted.

  * `:layout` - An optional layout the LiveView will be rendered in. Setting
    this option overrides the layout via `use Phoenix.LiveView`. This option
    may be overridden inside a LiveView by returning `{:ok, socket, layout: ...}`
    from the mount callback

## Examples

    scope "/", MyAppWeb do
      pipe_through :browser

      live_session :default do
        live "/feed", FeedLive, :index
        live "/status", StatusLive, :index
        live "/status/:id", StatusLive, :show
      end

      live_session :admin, on_mount: MyAppWeb.AdminLiveAuth do
        live "/admin", AdminDashboardLive, :index
        live "/admin/posts", AdminPostLive, :index
      end
    end

In the example above, we have two live sessions. Live navigation between live views
in the different sessions is not possible and will always require a full page reload.
This is important in the example above because the `:admin` live session has authentication
requirements, defined by `on_mount: MyAppWeb.AdminLiveAuth`, that the other LiveViews
do not have.

If you have both regular HTTP routes (via get, post, etc) and `live` routes, then
you need to perform the same authentication and authorization rules in both.
For example, if you were to add a `get "/admin/health"` route, then you must create
your own plug that performs the same authentication and authorization rules as
`MyAppWeb.AdminLiveAuth`, and then pipe through it:

    scope "/" do
      # Regular routes
      pipe_through [MyAppWeb.AdminPlugAuth]
      get "/admin/health", AdminHealthController, :index

      # Live routes
      live_session :admin, on_mount: MyAppWeb.AdminLiveAuth do
        live "/admin", AdminDashboardLive, :index
        live "/admin/posts", AdminPostLive, :index
      end
    end

## fetch_live_flash/2

Fetches the LiveView flash and merges with the controller flash.

Replaces the default `:fetch_flash` plug used by `Phoenix.Router`.

## Examples

    defmodule MyAppWeb.Router do
      use LiveGenWeb, :router
      import Phoenix.LiveView.Router

      pipeline :browser do
        ...
        plug :fetch_live_flash
      end
      ...
    end