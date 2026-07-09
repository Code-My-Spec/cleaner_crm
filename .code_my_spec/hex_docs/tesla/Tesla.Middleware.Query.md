# Tesla.Middleware.Query

Set default query params or serialize OpenAPI-style query values.

## Default Query Params

Pass a keyword list or map as the middleware argument to merge default query
params into every request:

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      {Tesla.Middleware.Query, [token: "some-token"]}
    ])
  end
end
```

## Modern OpenAPI Query Params

Use `mode: :modern` with `Tesla.OpenAPI.QueryParams` when generated clients need the
OpenAPI query parameter styles `:form`, `:space_delimited`,
`:pipe_delimited`, or `:deep_object`. Store the static parameter definitions
in request private data, then pass request values as a map. Other query params
remain normal Tesla query params:

```elixir
query_params =
  Tesla.OpenAPI.QueryParams.new!([
    Tesla.OpenAPI.QueryParam.new!("filter"),
    Tesla.OpenAPI.QueryParam.new!("ids", style: :pipe_delimited)
  ])

private = Tesla.OpenAPI.QueryParams.put_private(query_params)

client = Tesla.client([{Tesla.Middleware.Query, mode: :modern}])

Tesla.get(client, "/items",
  query: %{
    "filter" => [status: "open", owner: "yordis"],
    "ids" => [1, 2, 3],
    "debug" => true
  },
  private: private
)
```

Object-valued query params cover OpenAPI schemas with `additionalProperties`.
Unknown top-level query params, such as `"debug"` above, pass through as
normal Tesla query params.