# Plug.Router



## match_path/1

Returns the path of the route that the request was matched to.

## match/3

Main API to define routes.

It accepts an expression representing the path and many options
allowing the match to be configured.

The route can dispatch either to a function body or a Plug module.

## Examples

    match "/foo/bar", via: :get do
      send_resp(conn, 200, "hello world")
    end

    match "/baz", to: MyPlug, init_opts: [an_option: :a_value]

## Options

`match/3` and the other route macros accept the following options:

  * `:host` - the host which the route should match. Defaults to `nil`,
    meaning no host match, but can be a string like "example.com" or a
    string ending with ".", like "subdomain." for a subdomain match.

  * `:private` - assigns values to `conn.private` for use in the match

  * `:assigns` - assigns values to `conn.assigns` for use in the match

  * `:via` - matches the route against some specific HTTP method(s) specified
    as an atom, like `:get` or `:put`, or a list, like `[:get, :post]`.

  * `:do` - contains the implementation to be invoked in case
    the route matches.

  * `:to` - a Plug that will be called in case the route matches.

  * `:init_opts` - the options for the target Plug given by `:to`.

A route should specify only one of `:do` or `:to` options.

## get/3

Dispatches to the path only if the request is a GET request.
See `match/3` for more examples.

## head/3

Dispatches to the path only if the request is a HEAD request.
See `match/3` for more examples.

## post/3

Dispatches to the path only if the request is a POST request.
See `match/3` for more examples.

## put/3

Dispatches to the path only if the request is a PUT request.
See `match/3` for more examples.

## patch/3

Dispatches to the path only if the request is a PATCH request.
See `match/3` for more examples.

## delete/3

Dispatches to the path only if the request is a DELETE request.
See `match/3` for more examples.

## options/3

Dispatches to the path only if the request is an OPTIONS request.
See `match/3` for more examples.

## forward/2

Forwards requests to another Plug. The `path_info` of the forwarded
connection will exclude the portion of the path specified in the
call to `forward`. If the path contains any parameters, those will
be available in the target Plug in `conn.params` and `conn.path_params`.

## Options

`forward` accepts the following options:

  * `:to` - a Plug the requests will be forwarded to.
  * `:init_opts` - the options for the target Plug. It is the preferred
    mechanism for passing options to the target Plug.
  * `:host` - a string representing the host or subdomain, exactly like in
    `match/3`.
  * `:private` - values for `conn.private`, exactly like in `match/3`.
  * `:assigns` - values for `conn.assigns`, exactly like in `match/3`.

If `:init_opts` is undefined, then all remaining options are passed
to the target plug.

## Examples

    forward "/users", to: UserRouter

Assuming the above code, a request to `/users/sign_in` will be forwarded to
the `UserRouter` plug, which will receive what it will see as a request to
`/sign_in`.

    forward "/foo/:bar/qux", to: FooPlug

Here, a request to `/foo/BAZ/qux` will be forwarded to the `FooPlug`
plug, which will receive what it will see as a request to `/`,
and `conn.params["bar"]` will be set to `"BAZ"`.

Some other examples:

    forward "/foo/bar", to: :foo_bar_plug, host: "foobar."
    forward "/baz", to: BazPlug, init_opts: [plug_specific_option: true]