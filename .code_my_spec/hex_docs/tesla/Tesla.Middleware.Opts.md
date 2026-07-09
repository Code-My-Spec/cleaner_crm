# Tesla.Middleware.Opts

Set default opts for all requests.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      {Tesla.Middleware.Opts, [some: "option"]}
    ])
  end
end
```