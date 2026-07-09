# Tesla.Adapter.Hackney

Adapter for [hackney](https://github.com/benoitc/hackney).

Remember to add `{:hackney, "~> 1.21 or ~> 4.0 and >= 4.0.2"}` to dependencies (and `:hackney` to applications in `mix.exs`)
Also, you need to recompile tesla after adding `:hackney` dependency:

```shell
mix deps.clean tesla
mix deps.compile tesla
```

## Examples

```elixir
# set globally in config/config.exs
config :tesla, :adapter, Tesla.Adapter.Hackney

# set per module
defmodule MyClient do
  def client do
    Tesla.client([], Tesla.Adapter.Hackney)
  end
end
```

## Adapter specific options

- `:max_body` - Max response body size in bytes.
  Works for hackney 1.x and 4.x when streaming the response.
  Actual response may be bigger
  because hackney stops after the last chunk that surpasses `:max_body`.