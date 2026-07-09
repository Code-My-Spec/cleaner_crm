# Tesla.Middleware.DigestAuth

Digest access authentication middleware.

[Wiki on the topic](https://en.wikipedia.org/wiki/Digest_access_authentication)

**NOTE**: Currently the implementation is incomplete and works only for MD5 algorithm
and auth "quality of protection" (qop).

## Examples

```
defmodule MyClient do
  def client(username, password, opts \ %{}) do
    Tesla.client([
      {Tesla.Middleware.DigestAuth, Map.merge(%{username: username, password: password}, opts)}
    ])
  end
end
```

## Options

- `:username` - username (defaults to `""`)
- `:password` - password (defaults to `""`)
- `:cnonce_fn` - custom function generating client nonce (defaults to `&Tesla.Middleware.DigestAuth.cnonce/0`)
- `:nc` - nonce counter (defaults to `"00000000"`)