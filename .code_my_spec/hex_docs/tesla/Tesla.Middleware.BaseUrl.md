# Tesla.Middleware.BaseUrl

Set base URL for all requests.

By default, the base URL will be prepended to request path/URL only
if it does not include http(s). Use the `policy: :strict` option to
enforce base URL prepending regardless of scheme presence.

## Options

The options can be passed as a keyword list or a string representing the base URL.

- `:base_url` - The base URL to use for all requests.
- `:policy` - Can be set to `:strict` to enforce base URL prepending even when
  the request URL already includes a scheme. Useful for security when the URL is
  controlled by user input. Defaults to `:insecure`.

> ### Security Considerations {: .warning}
> When URLs are controlled by user input, always use `policy: :strict` to prevent
> URL redirection attacks. The default `:insecure` policy allows users to bypass
> the base URL by providing fully qualified URLs.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      # Using keyword format (recommended)
      {Tesla.Middleware.BaseUrl, base_url: "https://example.com/foo"}
      # or alternatively, using string
      # {Tesla.Middleware.BaseUrl, "https://example.com/foo"}
    ])
  end
end

client = MyClient.client()

Tesla.get(client, "/path")
# equals to GET https://example.com/foo/path

Tesla.get(client, "path")
# equals to GET https://example.com/foo/path

Tesla.get(client, "")
# equals to GET https://example.com/foo

Tesla.get(client, "http://example.com/bar")
# equals to GET http://example.com/bar (scheme detected, base URL not prepended)

# Using strict policy for user-controlled URLs (security)
defmodule MySecureClient do
  def client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, base_url: "https://example.com/foo", policy: :strict}
    ])
  end
end

secure_client = MySecureClient.client()

Tesla.get(secure_client, "http://example.com/bar")
# equals to GET https://example.com/foo/http://example.com/bar (base URL always prepended)

Tesla.get(secure_client, "/safe/path")
# equals to GET https://example.com/foo/safe/path
```