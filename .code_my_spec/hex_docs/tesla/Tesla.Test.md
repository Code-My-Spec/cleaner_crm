# Tesla.Test

Provides utilities for testing Tesla-based HTTP clients.

## assert_tesla_env/3

Asserts that two `t:Tesla.Env.t/0` structs match.

## Parameters

- `given_env` - The actual `t:Tesla.Env.t/0` struct received from the request.
- `expected_env` - The expected `t:Tesla.Env.t/0` struct to compare against.
- `opts` - Additional options for fine-tuning the assertion (optional).
  - `:exclude_headers` - A list of header keys to exclude from the assertion.

For the `body`, the function attempts to parse JSON and URL-encoded content
when appropriate.

This function is designed to be used in conjunction with
`Tesla.Test.assert_received_tesla_call/1` for comprehensive request
testing.

## Examples

    defmodule MyTest do
      use ExUnit.Case, async: true

      require Tesla.Test

      test "returns a 200 status" do
        given_env = %Tesla.Env{
          method: :post,
          url: "https://acme.com/users",
        }

        Tesla.Test.assert_tesla_env(given_env, %Tesla.Env{
          method: :post,
          url: "https://acme.com/users",
        })
      end
    end

## html/2

Puts an HTML response.

    iex> Tesla.Test.html(%Tesla.Env{}, "<html><body>Hello, world!</body></html>")
    %Tesla.Env{
      body: "<html><body>Hello, world!</body></html>",
      headers: [{"content-type", "text/html; charset=utf-8"}],
      ...
    }

## json/2

Puts a JSON response.

    iex> Tesla.Test.json(%Tesla.Env{}, %{"some" => "data"})
    %Tesla.Env{
      body: ~s({"some":"data"}),
      headers: [{"content-type", "application/json; charset=utf-8"}],
      ...
    }

If the body is binary, it will be returned as is and it will not try to encode
it to JSON.

## text/2

Puts a text response.

    iex> Tesla.Test.text(%Tesla.Env{}, "Hello, world!")
    %Tesla.Env{
      body: "Hello, world!",
      headers: [{"content-type", "text/plain; charset=utf-8"}],
      ...
    }

## assert_tesla_empty_mailbox/0

Asserts that the current process's mailbox does not contain any `Tesla.Test`
messages.

This function is designed to be used in conjunction with
`Tesla.Test.assert_received_tesla_call/1` for comprehensive request
testing.

## assert_received_tesla_call/3

Asserts that the current process's mailbox contains a `TeslaMox` message.
It uses `assert_received/1` under the hood.

## Parameters

- `expected_env` - The expected `t:Tesla.Env.t/0` passed to the adapter.
- `expected_opts` - The expected `t:Tesla.Adapter.options/0` passed to the
  adapter.
- `opts` - Extra configuration options.
  - `:adapter` - Optional. The adapter to expect the call on. Falls back to
    the `:tesla` application configuration.

## Examples

Asserting that the adapter received a `t:Tesla.Env.t/0` struct with a `200`
status:

    defmodule MyTest do
      use ExUnit.Case, async: true

      require Tesla.Test

      test "returns a 200 status" do
        # given - preconditions
        Tesla.Test.expect_tesla_call(
          times: 2,
          returns: %Tesla.Env{status: 200, body: "OK"}
        )

        # when - run unit of work
        # ... do some work ...
        Tesla.post!("https://acme.com/users")
        # ...

        # then - assertions
        Tesla.Test.assert_received_tesla_call(expected_env, expected_opts)
        Tesla.Test.assert_tesla_env(expected_env, %Tesla.Env{
          url: "https://acme.com/users",
          status: 200,
          body: "OK"
        })
        assert expected_opts == []
        Tesla.Test.assert_tesla_empty_mailbox()
      end
    end