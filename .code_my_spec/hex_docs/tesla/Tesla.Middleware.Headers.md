# Tesla.Middleware.Headers

Set default headers for all requests

## Examples

```elixir
defmodule Myclient do
  def client do
    Tesla.client([
      {Tesla.Middleware.Headers, [{"user-agent", "Tesla"}]}
    ])
  end
end
```