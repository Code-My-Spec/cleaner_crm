# Tesla.Middleware.Timeout

Timeout HTTP request after X milliseconds.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      {Tesla.Middleware.Timeout, timeout: 2_000}
    ])
  end
end
```

If you are using OpenTelemetry in your project, you may be interested in
using `OpentelemetryProcessPropagator.Task` to have a better integration using
the `task_module` option.

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      {Tesla.Middleware.Timeout, [
        timeout: 2_000,
        task_module: OpentelemetryProcessPropagator.Task
      }
    ])
  end
end
```

## Options

- `:timeout` - number of milliseconds a request is allowed to take (defaults to `1000`)
- `:task_module` - the `Task` module used to spawn tasks. Useful when you want
  to use alternatives such as `OpentelemetryProcessPropagator.Task` from the OTEL
  project.