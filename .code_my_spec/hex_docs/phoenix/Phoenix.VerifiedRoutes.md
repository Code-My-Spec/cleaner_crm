# Phoenix.VerifiedRoutes



## __before_compile__/1

Returns `true` if the path is verified, and false if not.

The `plug_opts` is typically only passed when the router is mounted within
a `Phoenix.Router`. Otherwise it defaults to `[]`.

## url/2

Generates the router url with route verification from the connection, socket, or URI.

See `url/1` for more information.

## url/3

Generates the url with route verification from the connection, socket, or URI and router.

See `url/1` for more information.

## static_url/2

Generates url to a static asset given its file path.

See `c:Phoenix.Endpoint.static_url/0` and `c:Phoenix.Endpoint.static_path/1` for more information.

## Examples

    iex> static_url(conn, "/assets/js/app.js")
    "https://example.com/assets/js/app-813dfe33b5c7f8388bccaaa38eec8382.js"

    iex> static_url(socket, "/assets/js/app.js")
    "https://example.com/assets/js/app-813dfe33b5c7f8388bccaaa38eec8382.js"

    iex> static_url(AppWeb.Endpoint, "/assets/js/app.js")
    "https://example.com/assets/js/app-813dfe33b5c7f8388bccaaa38eec8382.js"

## unverified_url/3

Returns the URL for the endpoint from the path without verification.

## Examples

    iex> unverified_url(conn, "/posts")
    "https://example.com/posts"

    iex> unverified_url(conn, "/posts", page: 1)
    "https://example.com/posts?page=1"

## static_path/2

Generates path to a static asset given its file path.

See `c:Phoenix.Endpoint.static_path/1` for more information.

## Examples

    iex> static_path(conn, "/assets/js/app.js")
    "/assets/js/app-813dfe33b5c7f8388bccaaa38eec8382.js"

    iex> static_path(socket, "assets/js/app.js")
    "/assets/js/app-813dfe33b5c7f8388bccaaa38eec8382.js"

    iex> static_path(AppWeb.Endpoint, "assets/js/app.js")
    "/assets/js/app-813dfe33b5c7f8388bccaaa38eec8382.js"

    iex> static_path(%URI{path: "/subresource"}, "/assets/js/app.js")
    "/subresource/assets/js/app-813dfe33b5c7f8388bccaaa38eec8382.js"

## unverified_path/4

Returns the path with relevant script name prefixes without verification.

## Examples

    iex> unverified_path(conn, AppWeb.Router, "/posts")
    "/posts"

    iex> unverified_path(conn, AppWeb.Router, "/posts", page: 1)
    "/posts?page=1"

## static_integrity/2

Generates an integrity hash to a static asset given its file path.

See `c:Phoenix.Endpoint.static_integrity/1` for more information.

## Examples

    iex> static_integrity(conn, "/assets/js/app.js")
    "813dfe33b5c7f8388bccaaa38eec8382"

    iex> static_integrity(socket, "/assets/js/app.js")
    "813dfe33b5c7f8388bccaaa38eec8382"

    iex> static_integrity(AppWeb.Endpoint, "/assets/js/app.js")
    "813dfe33b5c7f8388bccaaa38eec8382"