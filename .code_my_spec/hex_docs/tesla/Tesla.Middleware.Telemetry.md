# Tesla.Middleware.Telemetry

Emits events using the `:telemetry` library to expose instrumentation.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([Tesla.Middleware.Telemetry])
  end
end

:telemetry.attach(
  "my-tesla-telemetry",
  [:tesla, :request, :stop],
  fn event, measurements, meta, config ->
    # Do something with the event
  end,
  nil
)
```

## Options

- `:metadata` - additional metadata passed to telemetry events

## Telemetry Events

* `[:tesla, :request, :start]` - emitted at the beginning of the request.
  * Measurement: `%{system_time: System.system_time()}`
  * Metadata: `%{env: Tesla.Env.t()}`

* `[:tesla, :request, :stop]` - emitted at the end of the request.
  * Measurement: `%{duration: native_time}`
  * Metadata: `%{env: Tesla.Env.t()} | %{env: Tesla.Env.t(), error: term()}`

* `[:tesla, :request, :exception]` - emitted when an exception has been raised.
  * Measurement: `%{duration: native_time}`
  * Metadata: `%{env: Tesla.Env.t(), kind: Exception.kind(), reason: term(), stacktrace: Exception.stacktrace()}`

## Legacy Telemetry Events

  * `[:tesla, :request]` - This event is emitted for backwards compatibility only and should be considered deprecated.
      This event can be disabled by setting `config :tesla, Tesla.Middleware.Telemetry, disable_legacy_event: true` in your config.
      Be sure to run `mix deps.compile --force tesla` after changing this setting to ensure the change is picked up.

Please check the [telemetry](https://hexdocs.pm/telemetry/) for further usage.

## URL event scoping with `Tesla.Middleware.PathParams` and `Tesla.Middleware.KeepRequest`

Sometimes, it is useful to have access to a template URL (i.e. `"/users/:user_id"`) for grouping
Telemetry events. For such cases, a combination of the `Tesla.Middleware.PathParams`,
`Tesla.Middleware.Telemetry` and `Tesla.Middleware.KeepRequest` may be used.

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      # The KeepRequest middleware sets the template URL as a Tesla.Env.opts entry
      # Said entry must be used because on happy-path scenarios,
      # the Telemetry middleware will receive the Tesla.Env.url resolved by PathParams.
      Tesla.Middleware.KeepRequest,
      Tesla.Middleware.PathParams,
      Tesla.Middleware.Telemetry
    ])
  end
end

:telemetry.attach(
  "my-tesla-telemetry",
  [:tesla, :request, :stop],
  fn event, measurements, meta, config ->
    path_params_template_url = meta.env.opts[:req_url]
    # The meta.env.url key will only present the resolved URL on happy-path scenarios.
    # Error cases will still return the original template URL.
    path_params_resolved_url = meta.env.url
  end,
  nil
)
```

> #### Order Matters {: .warning}
> Place the `Tesla.Middleware.Telemetry` middleware as close as possible to
> the end of the middleware stack to ensure that you are measuring the
> actual request itself and do not lose any information about the
> `t:Tesla.Env.t/0` due to some transformation that happens in the
> middleware stack before reaching the `Tesla.Middleware.Telemetry`
> middleware.