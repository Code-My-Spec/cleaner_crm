# Tesla.Middleware.DecodeRels

Decode `Link` Hypermedia HTTP header into `opts[:rels]` field in response.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([Tesla.Middleware.DecodeRels])
  end
end

client = MyClient.client()

env = Tesla.get(client, "/...")

env.opts[:rels]
# => %{"Next" => "http://...", "Prev" => "..."}
```