# Phoenix.Router

Defines a Phoenix router.

The router provides a set of macros for generating routes
that dispatch to specific controllers and actions. Those
macros are named after HTTP verbs. For example:

    defmodule MyAppWeb.Router do
      use Phoenix.Router

      get "/pages/:page", PageController, :show
    end

The `get/3` macro above accepts a request to `/pages/hello` and dispatches
it to `PageController`'s `show` action with `%{"page" => "hello"}` in
`params`.

Phoenix's router is extremely efficient, as it relies on Elixir
pattern matching for matching routes and serving requests.

## Options

  * `:helpers` - whether to generate route helpers. Defaults to `true`.
    Helpers are deprecated, see the "Helpers" section below for more information

  * `:group_by` - when set to `:verb`, Phoenix groups route clauses per HTTP
    verb during compilation. This can reduce compilation times for large
    routers. When enabled, all `match :*` and `forward` routes must be defined
    at the end of the router

## Routing

`get/3`, `post/3`, `put/3`, and other macros named after HTTP verbs are used
to create routes.

The route:

    get "/pages", PageController, :index

matches a `GET` request to `/pages` and dispatches it to the `index` action in
`PageController`.

    get "/pages/:page", PageController, :show

matches `/pages/hello` and dispatches to the `show` action with
`%{"page" => "hello"}` in `params`.

    defmodule PageController do
      def show(conn, params) do
        # %{"page" => "hello"} == params
      end
    end

Partial and multiple segments can be matched. For example:

    get "/api/v:version/pages/:id", PageController, :show

matches `/api/v1/pages/2` and puts `%{"version" => "1", "id" => "2"}` in
`params`. Only the trailing part of a segment can be captured.

Routes are matched from top to bottom. The second route here:

    get "/pages/:page", PageController, :show
    get "/pages/hello", PageController, :hello

will never match `/pages/hello` because `/pages/:page` matches that first.

Routes can use glob-like patterns to match trailing segments.

    get "/pages/*page", PageController, :show

matches `/pages/hello/world` and puts the globbed segments in `params["page"]`.

    GET /pages/hello/world
    %{"page" => ["hello", "world"]} = params

Globs cannot have prefixes nor suffixes, but can be mixed with variables:

    get "/pages/he:page/*rest", PageController, :show

matches

    GET /pages/hello
    %{"page" => "llo", "rest" => []} = params

    GET /pages/hey/there/world
    %{"page" => "y", "rest" => ["there" "world"]} = params

> #### Why the macros? {: .info}
>
> Phoenix does its best to keep the usage of macros low. You may have noticed,
> however, that the `Phoenix.Router` relies heavily on macros. Why is that?
>
> We use `get`, `post`, `put`, and `delete` to define your routes. We use macros
> for two purposes:
>
> * They define the routing engine, used on every request, to choose which
>   controller to dispatch the request to. Thanks to macros, Phoenix compiles
>   all of your routes to a single case-statement with pattern matching rules,
>   which is heavily optimized by the Erlang VM
>
> * For each route you define, we also define metadata to implement `Phoenix.VerifiedRoutes`.
>   As we will soon learn, verified routes allows to us to reference any route
>   as if it is a plain looking string, except it is verified by the compiler
>   to be valid (making it much harder to ship broken links, forms, mails, etc
>   to production)
>
> In other words, the router relies on macros to build applications that are
> faster and safer. Also remember that macros in Elixir are compile-time only,
> which gives plenty of stability after the code is compiled. Phoenix also provides
> introspection for all defined routes via `mix phx.routes`.

## Generating routes

For generating routes inside your application,  see the `Phoenix.VerifiedRoutes`
documentation for `~p` based route generation which is the preferred way to
generate route paths and URLs with compile-time verification.

Phoenix also supports generating function helpers, which was the default
mechanism in Phoenix v1.6 and earlier. We will explore it next.

### Helpers (deprecated)

Phoenix generates a module `Helpers` inside your router by default, which contains
named helpers to help developers generate and keep their routes up to date.
Helpers can be disabled by passing `helpers: false` to `use Phoenix.Router`.

Helpers are automatically generated based on the controller name.
For example, the route:

    get "/pages/:page", PageController, :show

will generate the following named helper:

    MyAppWeb.Router.Helpers.page_path(conn_or_endpoint, :show, "hello")
    "/pages/hello"

    MyAppWeb.Router.Helpers.page_path(conn_or_endpoint, :show, "hello", some: "query")
    "/pages/hello?some=query"

    MyAppWeb.Router.Helpers.page_url(conn_or_endpoint, :show, "hello")
    "http://example.com/pages/hello"

    MyAppWeb.Router.Helpers.page_url(conn_or_endpoint, :show, "hello", some: "query")
    "http://example.com/pages/hello?some=query"

If the route contains glob-like patterns, parameters for those have to be given as
list:

    MyAppWeb.Router.Helpers.page_path(conn_or_endpoint, :show, ["hello", "world"])
    "/pages/hello/world"

The URL generated in the named URL helpers is based on the configuration for
`:url`, `:http` and `:https`. However, if for some reason you need to manually
control the URL generation, the url helpers also allow you to pass in a `URI`
struct:

    uri = %URI{scheme: "https", host: "other.example.com"}
    MyAppWeb.Router.Helpers.page_url(uri, :show, "hello")
    "https://other.example.com/pages/hello"

The named helper can also be customized with the `:as` option. Given
the route:

    get "/pages/:page", PageController, :show, as: :special_page

the named helper will be:

    MyAppWeb.Router.Helpers.special_page_path(conn, :show, "hello")
    "/pages/hello"

## Scopes and Resources

It is very common in Phoenix applications to namespace all of your
routes under the application scope:

    scope "/", MyAppWeb do
      get "/pages/:id", PageController, :show
    end

The route above will dispatch to `MyAppWeb.PageController`. This syntax
is convenient for developers, since we don't have to repeat `MyAppWeb.`
prefix on all routes

Like all paths, you can define dynamic segments that will be applied as
parameters in the controller:

    scope "/api/:version", MyAppWeb do
      get "/pages/:id", PageController, :show
    end

For example, the route above will match on the path `"/api/v1/pages/1"`
and in the controller the `params` argument will have a map with the
key `:version` with the value `"v1"`.

Phoenix also provides a `resources/4` macro that allows developers
to generate "RESTful" routes to a given resource:

    defmodule MyAppWeb.Router do
      use Phoenix.Router, helpers: false

      resources "/pages", PageController, only: [:show]
      resources "/users", UserController, except: [:delete]
    end

Finally, Phoenix ships with a `mix phx.routes` task that nicely
formats all routes in a given router. We can use it to verify all
routes included in the router above:

    $ mix phx.routes
    GET    /pages/:id       PageController.show/2
    GET    /users           UserController.index/2
    GET    /users/:id/edit  UserController.edit/2
    GET    /users/new       UserController.new/2
    GET    /users/:id       UserController.show/2
    POST   /users           UserController.create/2
    PATCH  /users/:id       UserController.update/2
    PUT    /users/:id       UserController.update/2

One can also pass a router explicitly as an argument to the task:

    $ mix phx.routes MyAppWeb.Router

Check `scope/2` and `resources/4` for more information.

## Pipelines and plugs

Once a request arrives at the Phoenix router, it performs
a series of transformations through pipelines until the
request is dispatched to a desired route.

Such transformations are defined via plugs, as defined
in the [Plug](https://github.com/elixir-lang/plug) specification.
Once a pipeline is defined, it can be piped through per scope.

For example:

    defmodule MyAppWeb.Router do
      use Phoenix.Router

      pipeline :browser do
        plug :fetch_session
        plug :accepts, ["html"]
      end

      scope "/" do
        pipe_through :browser

        # browser related routes and resources
      end
    end

`Phoenix.Router` imports functions from both `Plug.Conn` and `Phoenix.Controller`
to help define plugs. In the example above, `fetch_session/2`
comes from `Plug.Conn` while `accepts/2` comes from `Phoenix.Controller`.

Note that router pipelines are only invoked after a route is found.
No plug is invoked in case no matches were found.

## Learn more

See the [Routing](routing.md) guide for more information and examples
within an actual Phoenix application.

## match/5

Generates a route match based on an arbitrary HTTP method.

Useful for defining routes not included in the built-in macros.

The catch-all verb, `:*`, may also be used to match all HTTP methods.
If the router is configured with `group_by: :verb`, all `match :*` routes
must be defined at the end of the router, after all routes with explicit verbs.

## Options

  * `:as` - configures the named helper. If `nil`, does not generate
    a helper. Has no effect when using verified routes exclusively

  * `:alias` - configure if the scope alias should be applied to the route.
    Defaults to true, disables scoping if false

  * `:log` - the level to log the route dispatching under, may be set to false. Defaults to
    `:debug`. Route dispatching contains information about how the route is handled (which controller
    action is called, what parameters are available and which pipelines are used) and is separate from
    the plug level logging. To alter the plug log level, please see
    https://phoenix.hexdocs.pm/Phoenix.Logger.html#module-dynamic-log-level

  * `:private` - a map of private data to merge into the connection
    when a route matches

  * `:assigns` - a map of data to merge into the connection when a route matches

  * `:metadata` - a map of metadata used by the telemetry events and returned by
    `route_info/4`. The `:mfa` field is used by telemetry to print logs and by the
    router to emit compile time checks. Custom fields may be added

  * `:warn_on_verify` - the boolean for whether matches to this route in verified
    routes should emit a warning, rather than being accepted as verified. It is useful
    to ignore an otherwise catch-all route definition from being matched when verifying
    routes. Defaults `false`

## Examples

    match(:move, "/events/:id", EventController, :move)

    match(:*, "/any", SomeController, :any)

## pipeline/2

Defines a plug pipeline.

Pipelines are defined at the router root and can be used
from any scope.

## Examples

    pipeline :api do
      plug :token_authentication
      plug :dispatch
    end

A scope may then use this pipeline as:

    scope "/" do
      pipe_through :api
    end

Every time `pipe_through/1` is called, the new pipelines
are appended to the ones previously given.

## plug/2

Defines a plug inside a pipeline.

See `pipeline/2` for more information.

## pipe_through/1

Defines a list of plugs (and pipelines) to send the connection through.

Plugs are specified using the atom name of any imported 2-arity function
which takes a `Plug.Conn` and options and returns a `Plug.Conn`. For
example, `:require_authenticated_user`.

Pipelines are defined in the router, see `pipeline/2` for more information.

    pipe_through [:require_authenticated_user, :my_browser_pipeline]

## Multiple invocations

`pipe_through/1` can be invoked multiple times within the same scope. Each
invocation appends new plugs and pipelines to run, which are applied to all
routes **after** the `pipe_through/1` invocation. For example:

    scope "/" do
      pipe_through [:browser]
      get "/", HomeController, :index

      pipe_through [:require_authenticated_user]
      get "/settings", UserController, :edit
    end

In the example above, `/` pipes through `browser` only, while `/settings` pipes
through both `browser` and `require_authenticated_user`. Therefore, to avoid
confusion, we recommend a single `pipe_through` at the top of each scope:

    scope "/" do
      pipe_through [:browser]
      get "/", HomeController, :index
    end

    scope "/" do
      pipe_through [:browser, :require_authenticated_user]
      get "/settings", UserController, :edit
    end

## resources/4

Defines "RESTful" routes for a resource.

The given definition:

    resources "/users", UserController

will include routes to the following actions:

  * `GET /users` => `:index`
  * `GET /users/new` => `:new`
  * `POST /users` => `:create`
  * `GET /users/:id` => `:show`
  * `GET /users/:id/edit` => `:edit`
  * `PATCH /users/:id` => `:update`
  * `PUT /users/:id` => `:update`
  * `DELETE /users/:id` => `:delete`

## Options

This macro accepts a set of options:

  * `:only` - a list of actions to generate routes for, for example: `[:show, :edit]`
  * `:except` - a list of actions to exclude generated routes from, for example: `[:delete]`
  * `:param` - the name of the parameter for this resource, defaults to `"id"`
  * `:name` - the prefix for this resource. This is used for the named helper
    and as the prefix for the parameter in nested resources. The default value
    is automatically derived from the controller name, i.e. `UserController` will
    have name `"user"`
  * `:as` - configures the named helper. If `nil`, does not generate
    a helper. Has no effect when using verified routes exclusively
  * `:singleton` - defines routes for a singleton resource that is looked up by
    the client without referencing an ID. Read below for more information

## Singleton resources

When a resource needs to be looked up without referencing an ID, because
it contains only a single entry in the given context, the `:singleton`
option can be used to generate a set of routes that are specific to
such single resource:

  * `GET /user` => `:show`
  * `GET /user/new` => `:new`
  * `POST /user` => `:create`
  * `GET /user/edit` => `:edit`
  * `PATCH /user` => `:update`
  * `PUT /user` => `:update`
  * `DELETE /user` => `:delete`

Usage example:

    resources "/account", AccountController, only: [:show], singleton: true

## Nested Resources

This macro also supports passing a nested block of route definitions.
This is helpful for nesting children resources within their parents to
generate nested routes.

The given definition:

    resources "/users", UserController do
      resources "/posts", PostController
    end

will include the following routes:

```console
user_post_path  GET     /users/:user_id/posts           PostController :index
user_post_path  GET     /users/:user_id/posts/:id/edit  PostController :edit
user_post_path  GET     /users/:user_id/posts/new       PostController :new
user_post_path  GET     /users/:user_id/posts/:id       PostController :show
user_post_path  POST    /users/:user_id/posts           PostController :create
user_post_path  PATCH   /users/:user_id/posts/:id       PostController :update
                PUT     /users/:user_id/posts/:id       PostController :update
user_post_path  DELETE  /users/:user_id/posts/:id       PostController :delete
```

## resources/3

See `resources/4`.

## resources/2

See `resources/4`.

## scope/2

Defines a scope in which routes can be nested.

## Examples

    scope path: "/api/v1", alias: API.V1 do
      get "/pages/:id", PageController, :show
    end

The generated route above will match on the path `"/api/v1/pages/:id"`
and will dispatch to `:show` action in `API.V1.PageController`. A named
helper `api_v1_page_path` will also be generated.

## Options

The supported options are:

  * `:path` - a string containing the path scope.
  * `:as` - a string or atom containing the named helper scope. When set to
    false, it resets the nested helper scopes. Has no effect when using verified
    routes exclusively
  * `:alias` - an alias (atom) containing the controller scope. When set to
    false, it resets all nested aliases.
  * `:host` - a string or list of strings containing the host scope, or prefix host scope,
    ie `"foo.bar.com"`, `"foo."`
  * `:private` - a map of private data to merge into the connection when a route matches
  * `:assigns` - a map of data to merge into the connection when a route matches
  * `:log` - the level to log the route dispatching under, may be set to false. Defaults to
    `:debug`. Route dispatching contains information about how the route is handled (which controller
    action is called, what parameters are available and which pipelines are used) and is separate from
    the plug level logging. To alter the plug log level, please see
    https://phoenix.hexdocs.pm/Phoenix.Logger.html#module-dynamic-log-level.

## scope/3

Define a scope with the given path.

This function is a shortcut for:

    scope path: path do
      ...
    end

## Examples

    scope "/v1", host: "api." do
      get "/pages/:id", PageController, :show
    end

## scope/4

Defines a scope with the given path and alias.

This function is a shortcut for:

    scope path: path, alias: alias do
      ...
    end

## Examples

    scope "/v1", API.V1, host: "api." do
      get "/pages/:id", PageController, :show
    end

## scoped_alias/2

Returns the full alias with the current scope's aliased prefix.

Useful for applying the same short-hand alias handling to
other values besides the second argument in route definitions.

## Examples

    scope "/", MyPrefix do
      get "/", ProxyPlug, controller: scoped_alias(__MODULE__, MyController)
    end

## scoped_path/2

Returns the full path with the current scope's path prefix.

## forward/4

Forwards a request at the given path to a plug.

This is commonly used to forward all subroutes to another Plug.
For example:

    forward "/admin", SomeLib.AdminDashboard

The above will allow `SomeLib.AdminDashboard` to handle `/admin`,
`/admin/foo`, `/admin/bar/baz`, and so on. Furthermore,
`SomeLib.AdminDashboard` does not to be aware of the prefix it
is mounted in. From its point of view, the routes above are simply
handled as `/`, `/foo`, and `/bar/baz`.

A common use case for `forward` is for sharing a router between
applications or even breaking a big router into smaller ones.
However, in other for route generation to route accordingly, you
can only forward to a given `Phoenix.Router` once.

The router pipelines will be invoked prior to forwarding the
connection.

If the router is configured with `group_by: :verb`, all forwards must be
defined at the end of the router, after all routes with explicit verbs.

## Examples

    scope "/", MyApp do
      pipe_through [:browser, :admin]

      forward "/admin", SomeLib.AdminDashboard
      forward "/api", ApiRouter
    end

## routes/1

Returns all routes information from the given router.

## route_info/4

Returns the compile-time route info and runtime path params for a request.

The `path` can be either a string or the `path_info` segments.

A map of metadata is returned with the following keys:

  * `:log` - the configured log level. For example `:debug`
  * `:path_params` - the map of runtime path params
  * `:pipe_through` - the list of pipelines for the route's scope, for example `[:browser]`
  * `:plug` - the plug to dispatch the route to, for example `AppWeb.PostController`
  * `:plug_opts` - the options to pass when calling the plug, for example: `:index`
  * `:route` - the string route pattern, such as `"/posts/:id"`

## Examples

    iex> Phoenix.Router.route_info(AppWeb.Router, "GET", "/posts/123", "myhost")
    %{
      log: :debug,
      path_params: %{"id" => "123"},
      pipe_through: [:browser],
      plug: AppWeb.PostController,
      plug_opts: :show,
      route: "/posts/:id",
    }

    iex> Phoenix.Router.route_info(MyRouter, "GET", "/not-exists", "myhost")
    :error