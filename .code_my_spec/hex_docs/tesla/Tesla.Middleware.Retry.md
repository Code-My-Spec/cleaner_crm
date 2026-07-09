# Tesla.Middleware.Retry

Retry using exponential backoff and full jitter.

By defaults, this middleware only retries in the case of connection errors (`nxdomain`, `connrefused`, etc).
Application error checking for retry can be customized through `:should_retry` option.

## Backoff algorithm

The backoff algorithm optimizes for tight bounds on completing a request successfully.
It does this by first calculating an exponential backoff factor based on the
number of retries that have been performed.  It then multiplies this factor against
the base delay. The total maximum delay is found by taking the minimum of either
the calculated delay or the maximum delay specified. This creates an upper bound
on the maximum delay we can see.

In order to find the actual delay value we apply additive noise which is proportional
to the current desired delay. This ensures that the actual delay is kept within
the expected order of magnitude, while still having some randomness, which ensures
that our retried requests don't "harmonize" making it harder for the downstream service to heal.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      {Tesla.Middleware.Retry,
        delay: 500,
        max_retries: 10,
        max_delay: 4_000,
        should_retry: fn
          {:ok, %{status: status}}, _env, _context when status in [400, 500] -> true
          {:ok, _reason}, _env, _context -> false
          {:error, _reason}, %Tesla.Env{method: :post}, _context -> false
          {:error, _reason}, %Tesla.Env{method: :put}, %{retries: 2} -> false
          {:error, _reason}, _env, _context -> true
        end
      }
    ])
  end
end
```

## Options

- `:delay` - The base delay in milliseconds (positive integer, defaults to 50)
- `:max_retries` - maximum number of retries (non-negative integer, defaults to 5)
- `:max_delay` - maximum delay in milliseconds (positive integer, defaults to 5000)
- `:should_retry` - function with an arity of 1 or 3 used to determine if the request should
    be retried the first argument is the result, the second is the env and the third is
    the context: options + `:retries` (defaults to a match on `{:error, _reason}`)
- `:jitter_factor` - additive noise proportionality constant
    (float between 0 and 1, defaults to 0.2)
- `:use_retry_after_header` - whether to use the Retry-After header to determine the minimum
    delay before the next retry.  If the delay from the header exceeds max_delay, no further
    retries are attempted.  Invalid Retry-After headers are ignored.
    (boolean, defaults to false)