# Tesla.Adapter.Ibrowse

Adapter for [ibrowse](https://github.com/cmullaparthi/ibrowse).

Remember to add `{:ibrowse, "~> 4.2"}` to dependencies (and `:ibrowse` to applications in `mix.exs`)
Also, you need to recompile tesla after adding `:ibrowse` dependency:

```elixir
mix deps.clean tesla
mix deps.compile tesla
```

## Examples

```elixir
# set globally in config/config.exs
config :tesla, :adapter, Tesla.Adapter.Ibrowse

# set per module
defmodule MyClient do
  def client do
    Tesla.client([], Tesla.Adapter.Ibrowse)
  end
end
```