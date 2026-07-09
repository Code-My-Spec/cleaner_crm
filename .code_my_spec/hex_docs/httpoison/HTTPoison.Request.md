# HTTPoison.Request

`Request` properties:

  * `:method` - HTTP method as an atom (`:get`, `:head`, `:post`, `:put`,
    `:delete`, etc.)
  * `:url` - target url as a binary string or char list
  * `:body` - request body. See more below
  * `:headers` - HTTP headers as an orddict (e.g., `[{"Accept", "application/json"}]`)
  * `:options` - Keyword list of options
  * `:params` - Query parameters as a map, keyword, or orddict

`:body`:

  * binary, char list or an iolist
  * `{:form, [{K, V}, ...]}` - send a form url encoded
  * `{:file, "/path/to/file"}` - send a file
  * `{:stream, enumerable}` - lazily send a stream of binaries/charlists

`:options`:

  * `:timeout` - timeout for establishing a TCP or SSL connection, in milliseconds. Default is 8000
  * `:recv_timeout` - timeout for receiving an HTTP response from the socket. Default is 5000
  * `:stream_to` - a PID to stream the response to
  * `:async` - if given `:once`, will only stream one message at a time, requires call to `stream_next`
  * `:proxy` - a proxy to be used for the request; it can be a regular url
    or a `{Host, Port}` tuple, or a `{:socks5, ProxyHost, ProxyPort}` tuple
  * `:proxy_auth` - proxy authentication `{User, Password}` tuple
  * `:socks5_user`- socks5 username
  * `:socks5_pass`- socks5 password
  * `:ssl` - SSL options supported by the `ssl` erlang module. SSL defaults will be used where options
    are not specified.
  * `:ssl_override` - if `:ssl` is specified, this option is ignored, otherwise it can be used to
    completely override SSL settings.
  * `:follow_redirect` - a boolean that causes redirects to be followed, can cause a request to return
    a `MaybeRedirect` struct. See: HTTPoison.MaybeRedirect
  * `:max_redirect` - an integer denoting the maximum number of redirects to follow. Default is 5
  * `:params` - an enumerable consisting of two-item tuples that will be appended to the url as query string parameters
  * `:max_body_length` - a non-negative integer denoting the max response body length. See :hackney.body/2

  Timeouts can be an integer or `:infinity`

## to_curl/1

Returns an equivalent `curl` command for the given request.

## Examples
    iex> request = %HTTPoison.Request{url: "https://api.github.com", method: :get, headers: [{"Content-Type", "application/json"}]}
    iex> HTTPoison.Request.to_curl(request)
    "curl -X GET -H 'Content-Type: application/json' https://api.github.com ;"

    iex> request = HTTPoison.get!("https://api.github.com", [{"Content-Type", "application/json"}]).request
    iex> HTTPoison.Request.to_curl(request)
    "curl -X GET -H 'Content-Type: application/json' https://api.github.com ;"