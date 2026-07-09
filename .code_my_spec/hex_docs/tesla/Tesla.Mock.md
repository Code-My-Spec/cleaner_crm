# Tesla.Mock

Mock adapter for better testing.

> #### Deprecated {: .warning}
>
> Use a Mox adapter with `Tesla.Test` helpers for new tests.

## Setup

```elixir
# config/test.exs
config :tesla, adapter: Tesla.Mock

# in case MyClient defines specific adapter with `adapter SpecificAdapter`
config :tesla, MyClient, adapter: Tesla.Mock
```

## Examples

```elixir
defmodule MyAppTest do
  use ExUnit.Case

  setup do
    Tesla.Mock.mock(fn
      %{method: :get} ->
        %Tesla.Env{status: 200, body: "hello"}
    end)

    :ok
  end

  test "list things" do
    assert {:ok, env} = MyApp.get("...")
    assert env.status == 200
    assert env.body == "hello"
  end
end
```

## Setting up mocks

```elixir
# Match on method & url and return whole Tesla.Env
Tesla.Mock.mock(fn
  %{method: :get, url: "http://example.com/list"} ->
    %Tesla.Env{status: 200, body: "hello"}
end)

# You can use any logic required
Tesla.Mock.mock(fn env ->
  case env.url do
    "http://example.com/list" ->
      %Tesla.Env{status: 200, body: "ok!"}

    _ ->
      %Tesla.Env{status: 404, body: "NotFound"}
  end
end)


# mock will also accept short version of response
# in the form of {status, headers, body}
Tesla.Mock.mock(fn
  %{method: :post} -> {201, %{}, %{id: 42}}
end)

# mock will also accept error tuples in the form
# of {:error, reason}
Tesla.Mock.mock(fn
  %{method: :post} -> {:error, :timeout}
end)
```

## Global mocks

By default, mocks are bound to the current process,
i.e. the process running a single test case.
This design allows proper isolation between test cases
and make testing in parallel (`async: true`) possible.

While this style is recommended, there is one drawback:
if Tesla client is called from different process
it will not use the setup mock.

To solve this issue it is possible to setup a global mock
using `mock_global/1` function.

```elixir
defmodule MyTest do
  use ExUnit.Case, async: false # must be false!

  setup_all do
    Tesla.Mock.mock_global fn
      env -> # ...
    end

    :ok
  end

  # ...
end
```

**WARNING**: Using global mocks may affect tests with local mock
(because of fallback to global mock in case local one is not found)

## mock/1

Setup mocks for current test.

This mock will only be available to the current process.

## mock_global/1

Setup global mocks.

**WARNING**: This mock will be available to ALL processes.
It might cause conflicts when running tests in parallel!

## json/2

Return JSON response.

Example

    import Tesla.Mock

    mock fn
      %{url: "/ok"} -> json(%{"some" => "data"})
      %{url: "/404"} -> json(%{"some" => "data"}, status: 404)
    end

## text/2

Return text response.

Example

    import Tesla.Mock

    mock fn
      %{url: "/ok"} -> text("200 ok")
      %{url: "/404"} -> text("404 not found", status: 404)
    end