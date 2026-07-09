# Phoenix.Controller

Controllers are used to group common functionality in the same
(pluggable) module.

For example, the route:

    get "/users/:id", MyAppWeb.UserController, :show

will invoke the `show/2` action in the `MyAppWeb.UserController`:

    defmodule MyAppWeb.UserController do
      use MyAppWeb, :controller

      def show(conn, %{"id" => id}) do
        user = Repo.get(User, id)
        render(conn, :show, user: user)
      end
    end

An action is a regular function that receives the connection
and the request parameters as arguments. The connection is a
`Plug.Conn` struct, as specified by the Plug library.

Then we invoke `render/3`, passing the connection, the template
to render (typically named after the action), and the `user: user`
as assigns. We will explore all of those concepts next.

## Connection

A controller by default provides many convenience functions for
manipulating the connection, rendering templates, and more.

Those functions are imported from two modules:

  * `Plug.Conn` - a collection of low-level functions to work with
    the connection

  * `Phoenix.Controller` - functions provided by Phoenix
    to support rendering, and other Phoenix specific behaviour

If you want to have functions that manipulate the connection
without fully implementing the controller, you can import both
modules directly instead of `use Phoenix.Controller`.

## Rendering

One of the main features provided by controllers is the ability
to perform content negotiation and render templates based on
information sent by the client.

There are two ways to render content in a controller. One option
is to invoke format-specific functions, such as `html/2` and `json/2`.

However, most commonly controllers invoke custom modules called
views. Views are modules capable of rendering a custom format.
This is done by specifying the option `:formats` when defining
the controller:

    use Phoenix.Controller, formats: [:html, :json]

 Now, when invoking `render/3`, a controller named `MyAppWeb.UserController`
 will invoke `MyAppWeb.UserHTML` and `MyAppWeb.UserJSON` respectively
 when rendering each format:

    def show(conn, %{"id" => id}) do
      user = Repo.get(User, id)
      # Will invoke UserHTML.show(%{user: user}) for html requests
      # Will invoke UserJSON.show(%{user: user}) for json requests
      render(conn, :show, user: user)
    end

You can also specify formats to render by calling `put_view/2`
directly with a connection. For example, instead of inferring the
the view names from the controller, as done in:

    use Phoenix.Controller, formats: [:html, :json]

You can write the above explicitly in your actions as:

    put_view(conn, html: MyAppWeb.UserHTML, json: MyAppWeb.UserJSON)

Or as a plug:

    plug :put_view, html: MyAppWeb.UserHTML, json: MyAppWeb.UserJSON

## Layouts

Many applications have shared content that they want to include on every
page, most often the `<head>` tag and its contents. In Phoenix, this is
done via the `put_root_layout` function:

    put_root_layout(conn, html: {MyAppWeb.Layouts, :root})

In most applications, this is invoked as a Plug in your application router:

    plug :put_root_layout, html: {MyAppWeb.Layouts, :root}

This layout is shared by all controllers, and also by `Phoenix.LiveView`.

However, you can also specify controller-specific layouts using `put_layout/2`,
although this functionality is discouraged in Phoenix v1.8 in favor of using
function components to build your application.

## Options

When used, the controller supports the following options to customize
template rendering:

  * `:formats` - the formats this controller will render
    by default. For example, specifying `formats: [:html, :json]`
    for a controller named `MyAppWeb.UserController` will
    invoke `MyAppWeb.UserHTML` and `MyAppWeb.UserJSON` when
    respectively rendering each format.

The `:formats` option is required. You may set it to an empty list
if you don't expect to render any format upfront. To retain the
behaviour of older Phoenix versions, you can explicitly pass the
"View" suffix to the `:formats` option:

    use Phoenix.Controller, formats: [html: "View", json: "View"]

## Plug pipeline

As with routers, controllers also have their own plug pipeline.
However, different from routers, controllers have a single pipeline:

    defmodule MyAppWeb.UserController do
      use MyAppWeb, :controller

      plug :authenticate, usernames: ["jose", "eric", "sonny"]

      def show(conn, params) do
        # authenticated users only
      end

      defp authenticate(conn, options) do
        if get_session(conn, :username) in options[:usernames] do
          conn
        else
          conn |> redirect(to: "/") |> halt()
        end
      end
    end

The `:authenticate` plug will be invoked before the action. If the
plug calls `Plug.Conn.halt/1` (which is by default imported into
controllers), it will halt the pipeline and won't invoke the action.

### Guards

`plug/2` in controllers supports guards, allowing a developer to configure
a plug to only run in some particular action.

    plug :do_something when action in [:show, :edit]

Due to operator precedence in Elixir, if the second argument is a keyword list,
we need to wrap the keyword in `[...]` when using `when`:

    plug :authenticate, [usernames: ["jose", "eric", "sonny"]] when action in [:show, :edit]
    plug :authenticate, [usernames: ["admin"]] when not action in [:index]

The first plug will run only when action is show or edit. The second plug will
always run, except for the index action.

Those guards work like regular Elixir guards and the only variables accessible
in the guard are `conn`, the `action` as an atom and the `controller` as an
alias.

## Controllers are plugs

Like routers, controllers are plugs, but they are wired to dispatch
to a particular function which is called an action.

For example, the route:

    get "/users/:id", UserController, :show

will invoke `UserController` as a plug:

    UserController.call(conn, :show)

which will trigger the plug pipeline and which will eventually
invoke the inner action plug that dispatches to the `show/2`
function in `UserController`.

As controllers are plugs, they implement both [`init/1`](`c:Plug.init/1`) and
[`call/2`](`c:Plug.call/2`), and it also provides a function named `action/2`
which is responsible for dispatching the appropriate action
after the plug stack (and is also overridable).

### Overriding `action/2` for custom arguments

Phoenix injects an `action/2` plug in your controller which calls the
function matched from the router. By default, it passes the conn and params.
In some cases, overriding the `action/2` plug in your controller is a
useful way to inject arguments into your actions that you would otherwise
need to repeatedly fetch off the connection. For example, imagine if you
stored a `conn.assigns.current_user` in the connection and wanted quick
access to the user for every action in your controller:

    def action(conn, _) do
      args = [conn, conn.params, conn.assigns.current_user]
      apply(__MODULE__, action_name(conn), args)
    end

    def index(conn, _params, user) do
      videos = Repo.all(user_videos(user))
      # ...
    end

    def delete(conn, %{"id" => id}, user) do
      video = Repo.get!(user_videos(user), id)
      # ...
    end

## action_fallback/1

Registers the plug to call as a fallback to the controller action.

A fallback plug is useful to translate common domain data structures
into a valid `%Plug.Conn{}` response. If the controller action fails to
return a `%Plug.Conn{}`, the provided plug will be called and receive
the controller's `%Plug.Conn{}` as it was before the action was invoked
along with the value returned from the controller action.

## Examples

    defmodule MyController do
      use Phoenix.Controller

      action_fallback MyFallbackController

      def show(conn, %{"id" => id}, current_user) do
        with {:ok, post} <- Blog.fetch_post(id),
             :ok <- Authorizer.authorize(current_user, :view, post) do

          render(conn, "show.json", post: post)
        end
      end
    end

In the above example, `with` is used to match only a successful
post fetch, followed by valid authorization for the current user.
In the event either of those fail to match, `with` will not invoke
the render block and instead return the unmatched value. In this case,
imagine `Blog.fetch_post/2` returned `{:error, :not_found}` or
`Authorizer.authorize/3` returned `{:error, :unauthorized}`. For cases
where these data structures serve as return values across multiple
boundaries in our domain, a single fallback module can be used to
translate the value into a valid response. For example, you could
write the following fallback controller to handle the above values:

    defmodule MyFallbackController do
      use Phoenix.Controller

      def call(conn, {:error, :not_found}) do
        conn
        |> put_status(:not_found)
        |> put_view(MyErrorView)
        |> render(:"404")
      end

      def call(conn, {:error, :unauthorized}) do
        conn
        |> put_status(:forbidden)
        |> put_view(MyErrorView)
        |> render(:"403")
      end
    end

## action_name/1

Returns the action name as an atom, raises if unavailable.

## controller_module/1

Returns the controller module as an atom, raises if unavailable.

## router_module/1

Returns the router module as an atom, raises if unavailable.

## endpoint_module/1

Returns the endpoint module as an atom, raises if unavailable.

## view_template/1

Returns the template name rendered in the view as a string
(or nil if no template was rendered).

## json/2

Sends JSON response.

It uses the configured `:json_library` under the `:phoenix`
application for `:json` to pick up the encoder module.

## Examples

    iex> json(conn, %{id: 123})

## allow_jsonp/2

A plug that may convert a JSON response into a JSONP one.

In case a JSON response is returned, it will be converted
to a JSONP as long as the callback field is present in
the query string. The callback field itself defaults to
"callback", but may be configured with the callback option.

In case there is no callback or the response is not encoded
in JSON format, it is a no-op.

Only alphanumeric characters and underscore are allowed in the
callback name. Otherwise an exception is raised.

## Examples

    # Will convert JSON to JSONP if callback=someFunction is given
    plug :allow_jsonp

    # Will convert JSON to JSONP if cb=someFunction is given
    plug :allow_jsonp, callback: "cb"

## text/2

Sends text response.

## Examples

    iex> text(conn, "hello")

    iex> text(conn, :implements_to_string)

## html/2

Sends html response.

## Examples

    iex> html(conn, "<html><head>...")

## redirect/2

Sends redirect response to the given url.

For security, `:to` only accepts paths. Use the `:external`
option to redirect to any URL.

The response will be sent with the status code defined within
the connection, via `Plug.Conn.put_status/2`. If no status
code is set, a 302 response is sent.

## Examples

    iex> redirect(conn, to: "/login")

    iex> redirect(conn, external: "https://elixir-lang.org")

## put_view/2

Stores the view for rendering.

Raises `Plug.Conn.AlreadySentError` if `conn` is already sent.

## Examples

    iex> put_view(conn, html: AppHTML, json: AppJSON)

## put_new_view/2

Stores the view for rendering if one was not stored yet.

Raises `Plug.Conn.AlreadySentError` if `conn` is already sent.

## view_module/2

Retrieves the current view for the given format.

If no format is given, takes the current one from the connection.

## put_layout/2

Stores the layout for rendering.

The layout must be given as keyword list where the key is the request
format the layout will be applied to (such as `:html`) and the value
is one of:

  * `{module, layout}` with the `module` the layout is defined and
    the name of the `layout` as an atom

  * `false` which disables the layout

If `false` is given without a format, all layouts are disabled.

## Examples

    iex> layout(conn)
    false

    iex> conn = put_layout(conn, html: {AppView, :application})
    iex> layout(conn)
    {AppView, :application}

    iex> conn = put_layout(conn, html: {AppView, :print})
    iex> layout(conn)
    {AppView, :print}

Raises `Plug.Conn.AlreadySentError` if `conn` is already sent.

## put_new_layout/2

Stores the layout for rendering if one was not stored yet.

See `put_layout/2` for more information.

Raises `Plug.Conn.AlreadySentError` if `conn` is already sent.

## put_root_layout/2

Stores the root layout for rendering.

The layout must be given as keyword list where the key is the request
format the layout will be applied to (such as `:html`) and the value
is one of:

  * `{module, layout}` with the `module` the layout is defined and
    the name of the `layout` as an atom

  * `layout` when the name of the layout. This requires a layout for
    the given format in the shape of `{module, layout}` to be previously
    given

  * `false` which disables the layout

## Examples

    iex> root_layout(conn)
    false

    iex> conn = put_root_layout(conn, html: {AppView, :root})
    iex> root_layout(conn)
    {AppView, :root}

    iex> conn = put_root_layout(conn, html: :bare)
    iex> root_layout(conn)
    {AppView, :bare}

Raises `Plug.Conn.AlreadySentError` if `conn` is already sent.

## layout/2

Retrieves the current layout for the given format.

If no format is given, takes the current one from the connection.

## root_layout/2

Retrieves the current root layout for the given format.

If no format is given, takes the current one from the connection.

## render/2

Render the given template or the default template
specified by the current action with the given assigns.

See `render/3` for more information.

## render/3

Renders the given `template` and `assigns` based on the `conn` information.

Once the template is rendered, the template format is set as the response
content type (for example, an HTML template will set "text/html" as response
content type) and the data is sent to the client with default status of 200.

## Arguments

  * `conn` - the `Plug.Conn` struct

  * `template` - which may be an atom or a string. If an atom, like `:index`,
    it will render a template with the same format as the one returned by
    `get_format/1`. For example, for an HTML request, it will render
    the "index.html" template. If the template is a string, it must contain
    the extension too, like "index.json"

  * `assigns` - a dictionary with the assigns to be used in the view. Those
    assigns are merged and have higher precedence than the connection assigns
    (`conn.assigns`)

## Examples

To render a template, you must configure your controller with the formats
to render. You can do so on `use`, which will infer the modules based on
the controller name:

    defmodule MyAppWeb.UserController do
      # Will use MyAppWeb.UserHTML and MyAppWeb.UserJSON
      use Phoenix.Controller, formats: [:html, :json]
    end

With the formats set, you can render in two ways, either passing a string
with the template name and explicit format:

    def show(conn, _params) do
      render(conn, "show.html", message: "Hello")
    end

The example above renders a template "show.html" from the `MyAppWeb.UserHTML`
and sets the response content type to "text/html".

Or, if you want the template format to be set dynamically based on the request,
you can pass an atom instead (without the extension):

    def show(conn, _params) do
      render(conn, :show, message: "Hello")
    end

If the formats are not known at compile-time, you can call `put_view/2`
at runtime:

    defmodule MyAppWeb.UserController do
      use Phoenix.Controller

      def show(conn, _params) do
        conn
        |> put_view(html: MyAppWeb.UserHTML)
        |> render("show.html", message: "Hello")
      end
    end

## put_router_url/2

Puts the url string or `%URI{}` to be used for route generation.

This function overrides the default URL generation pulled
from the `%Plug.Conn{}`'s endpoint configuration.

## Examples

Imagine your application is configured to run on "example.com"
but after the user signs in, you want all links to use
"some_user.example.com". You can do so by setting the proper
router url configuration:

    def put_router_url_by_user(conn) do
      put_router_url(conn, get_user_from_conn(conn).account_name <> ".example.com")
    end

Now when you call `Routes.some_route_url(conn, ...)`, it will use
the router url set above. Keep in mind that, if you want to generate
routes to the *current* domain, it is preferred to use
`Routes.some_route_path` helpers, as those are always relative.

## put_static_url/2

Puts the URL or `%URI{}` to be used for the static url generation.

Using this function on a `%Plug.Conn{}` struct tells `static_url/2` to use
the given information for URL generation instead of the `%Plug.Conn{}`'s
endpoint configuration (much like `put_router_url/2` but for static URLs).

## put_format/2

Puts the format in the connection.

This format is used when rendering a template as an atom.
For example, `render(conn, :foo)` will render `"foo.FORMAT"`
where the format is the one set here. The default format
is typically set from the negotiation done in `accepts/2`.

See `get_format/1` for retrieval.

## get_format/1

Returns the request format, such as "json", "html".

This format is used when rendering a template as an atom.
For example, `render(conn, :foo)` will render `"foo.FORMAT"`
where the format is the one set here. The default format
is typically set from the negotiation done in `accepts/2`.

## send_download/3

Sends the given file or binary as a download.

The second argument must be `{:binary, contents}`, where
`contents` will be sent as download, or`{:file, path}`,
where `path` is the filesystem location of the file to
be sent. Be careful to not interpolate the path from
external parameters, as it could allow traversal of the
filesystem.

The download is achieved by setting "content-disposition"
to attachment. The "content-type" will also be set based
on the extension of the given filename but can be customized
via the `:content_type` and `:charset` options.

## Options

  * `:filename` - the filename to be presented to the user
    as download
  * `:content_type` - the content type of the file or binary
    sent as download. It is automatically inferred from the
    filename extension
  * `:disposition` - specifies disposition type
    (`:attachment` or `:inline`). If `:attachment` was used,
    user will be prompted to save the file. If `:inline` was used,
    the browser will attempt to open the file.
    Defaults to `:attachment`.
  * `:charset` - the charset of the file, such as "utf-8".
    Defaults to none
  * `:offset` - the bytes to offset when reading. Defaults to `0`
  * `:length` - the total bytes to read. Defaults to `:all`
  * `:encode` - encodes the filename using `URI.encode/2`.
    Defaults to `true`. When `false`, disables encoding. If you
    disable encoding, you need to guarantee there are no special
    characters in the filename, such as quotes, newlines, etc.
    Otherwise you can expose your application to security attacks

## Examples

To send a file that is stored inside your application priv
directory:

    path = Application.app_dir(:my_app, "priv/prospectus.pdf")
    send_download(conn, {:file, path})

When using `{:file, path}`, the filename is inferred from the
given path but may also be set explicitly.

To allow the user to download contents that are in memory as
a binary or string:

    send_download(conn, {:binary, "world"}, filename: "hello.txt")

See `Plug.Conn.send_file/3` and `Plug.Conn.send_resp/3` if you
would like to access the low-level functions used to send files
and responses via Plug.

## scrub_params/2

Scrubs the parameters from the request.

This process is two-fold:

  * Checks to see if the `required_key` is present
  * Changes empty parameters of `required_key` (recursively) to nils

This function is useful for removing empty strings sent
via HTML forms. If you are providing an API, there
is likely no need to invoke `scrub_params/2`.

If the `required_key` is not present, it will
raise `Phoenix.MissingParamError`.

## Examples

    iex> scrub_params(conn, "user")

## protect_from_forgery/2

Enables CSRF protection.

Currently used as a wrapper function for `Plug.CSRFProtection`
and mainly serves as a function plug in `YourApp.Router`.

Check `get_csrf_token/0` and `delete_csrf_token/0` for
retrieving and deleting CSRF tokens.

## put_secure_browser_headers/2

Put headers that improve browser security.

It sets the following headers, if they are not already set:

  * `content-security-policy` - It sets `frame-ancestors` and
    `base-uri` to `self`, restricting embedding and the use of
    `<base>` element to same origin respectively. It is equivalent
    to setting `"base-uri 'self'; frame-ancestors 'self';"`

  * `referrer-policy` - only send origin on cross origin requests

  * `x-content-type-options` - set to nosniff. This requires
    script and style tags to be sent with proper content type

  * `x-permitted-cross-domain-policies` - set to none to restrict
    Adobe Flash Player’s access to data

A custom headers map may also be given to be merged with defaults.

It is recommended for custom header keys to be in lowercase, to avoid sending
duplicate keys or invalid responses.

## accepts/2

Performs content negotiation based on the available formats.

It receives a connection, a list of formats that the server
is capable of rendering and then proceeds to perform content
negotiation based on the request information. If the client
accepts any of the given formats, the request proceeds.

If the request contains a "_format" parameter, it is
considered to be the format desired by the client. If no
"_format" parameter is available, this function will parse
the "accept" header and find a matching format accordingly.

This function is useful when you may want to serve different
content-types (such as JSON and HTML) from the same routes.
However, if you always have distinct routes, you can also
disable content negotiation and simply hardcode your format
of choice in your route pipelines:

    plug :put_format, "html"

It is important to notice that browsers have historically
sent bad accept headers. For this reason, this function will
default to "html" format whenever:

  * the accepted list of arguments contains the "html" format

  * the accept header specified more than one media type preceded
    or followed by the wildcard media type "`*/*`"

This function raises `Phoenix.NotAcceptableError`, which is rendered
with status 406, whenever the server cannot serve a response in any
of the formats expected by the client.

## Examples

`accepts/2` can be invoked as a function:

    iex> accepts(conn, ["html", "json"])

or used as a plug:

    plug :accepts, ["html", "json"]
    plug :accepts, ~w(html json)

## Custom media types

It is possible to add custom media types to your Phoenix application.
The first step is to teach Plug about those new media types in
your `config/config.exs` file:

    config :mime, :types, %{
      "application/vnd.api+json" => ["json-api"]
    }

The key is the media type, the value is a list of formats the
media type can be identified with. For example, by using
"json-api", you will be able to use templates with extension
"index.json-api" or to force a particular format in a given
URL by sending "?_format=json-api".

After this change, you must recompile plug:

    $ mix deps.clean mime --build
    $ mix deps.get

And now you can use it in accepts too:

    plug :accepts, ["html", "json-api"]

## fetch_flash/2

Fetches the flash storage.

## merge_flash/2

Merges a map into the flash.

Returns the updated connection.

## Examples

    iex> conn = merge_flash(conn, info: "Welcome Back!")
    iex> Phoenix.Flash.get(conn.assigns.flash, :info)
    "Welcome Back!"

## put_flash/3

Persists a value in flash.

`key` can be any atom or binary value. Phoenix does not enforce which keys
are stored in the flash, as long as the values are internally consistent.
By default, the Phoenix generators use `:info` and `:error` keys.

Returns the updated connection.

## Examples

    iex> conn = put_flash(conn, :info, "Welcome Back!")
    iex> Phoenix.Flash.get(conn.assigns.flash, :info)
    "Welcome Back!"

## get_flash/1

Returns a map of previously set flash messages or an empty map.

## Examples

    iex> get_flash(conn)
    %{}

    iex> conn = put_flash(conn, :info, "Welcome Back!")
    iex> get_flash(conn)
    %{"info" => "Welcome Back!"}

## get_flash/2

Returns a message from flash by `key` (or `nil` if no message is available for `key`).

## Examples

    iex> conn = put_flash(conn, :info, "Welcome Back!")
    iex> get_flash(conn, :info)
    "Welcome Back!"

## status_message_from_template/1

Generates a status message from the template name.

## Examples

    iex> status_message_from_template("404.html")
    "Not Found"
    iex> status_message_from_template("whatever.html")
    "Internal Server Error"

## clear_flash/1

Clears all flash messages.

## current_path/1

Returns the current request path with its default query parameters:

    iex> current_path(conn)
    "/users/123?existing=param"

See `current_path/2` to override the default parameters.

The path is normalized based on the `conn.script_name` and
`conn.path_info`. For example, "/foo//bar/" will become "/foo/bar".
If you want the original path, use `conn.request_path` instead.

## current_path/2

Returns the current path with the given query parameters.

You may also retrieve only the request path by passing an
empty map of params.

## Examples

    iex> current_path(conn)
    "/users/123?existing=param"

    iex> current_path(conn, %{new: "param"})
    "/users/123?new=param"

    iex> current_path(conn, %{filter: %{status: ["draft", "published"]}})
    "/users/123?filter[status][]=draft&filter[status][]=published"

    iex> current_path(conn, %{})
    "/users/123"

The path is normalized based on the `conn.script_name` and
`conn.path_info`. For example, "/foo//bar/" will become "/foo/bar".
If you want the original path, use `conn.request_path` instead.

## current_url/1

Returns the current request url with its default query parameters:

    iex> current_url(conn)
    "https://www.example.com/users/123?existing=param"

See `current_url/2` to override the default parameters.

## assign/2

Assigns multiple key-value pairs to the connection.
Accepts a keyword list, a map, or a single-argument function.

This function accepts a map or keyword list of assigns and merges them into
the connection's assigns. It is equivalent to calling `Plug.Conn.assign/3`
multiple times.

If a function is given, it takes the current assigns as an argument and its return
value will be merged into the current assigns.

## Examples

    assign(conn, name: "Alice", role: :admin)
    assign(conn, %{name: "Alice", role: :admin})
    assign(conn, fn %{name: name, logo: logo} -> %{title: Enum.join([name, logo], " | ")} end)