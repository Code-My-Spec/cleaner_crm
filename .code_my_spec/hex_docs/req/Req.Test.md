# Req.Test

Req testing conveniences.

Req is composed of:

  * `Req` - the high-level API

  * `Req.Request` - the low-level API and the request struct

  * `Req.Steps` - the collection of built-in steps

  * `Req.Test` - the testing conveniences (you're here!)

Req already has built-in support for different variants of stubs via `:plug`, `:adapter`,
and (indirectly) `:base_url` options. With this module you can:

  * Create request stubs using [`Req.Test.stub(name, plug)`](`stub/2`) and mocks
    using [`Req.Test.expect(name, count, plug)`](`expect/3`). Both can be used in concurrent
    tests.

  * Configure Req to run requests through mocks/stubs by setting `plug: {Req.Test, name}`.
    This works because `Req.Test` itself is a plug whose job is to fetch the mocks/stubs under
    `name`.

  * Easily create JSON responses with [`Req.Test.json(conn, body)`](`json/2`),
    HTML responses with [`Req.Test.html(conn, body)`](`html/2`), and
    text responses with [`Req.Test.text(conn, body)`](`text/2`).

  * Simulate network errors with [`Req.Test.transport_error(conn, reason)`](`transport_error/2`).

Mocks and stubs are using the same ownership model of
[nimble_ownership](https://hex.pm/packages/nimble_ownership), also used by
[Mox](https://hex.pm/packages/mox). This allows `Req.Test` to be used in concurrent tests.

## Example

Imagine we're building an app that displays weather for a given location using an HTTP weather
service:

    defmodule MyApp.Weather do
      def get_rating(location) do
        case get_temperature(location) do
          {:ok, %{status: 200, body: %{"celsius" => celsius}}} ->
            cond do
              celsius < 18.0 -> {:ok, :too_cold}
              celsius < 30.0 -> {:ok, :nice}
              true -> {:ok, :too_hot}
            end

          _ ->
            :error
        end
      end

      def get_temperature(location) do
        [
          base_url: "https://weather-service",
          params: [location: location]
        ]
        |> Keyword.merge(Application.get_env(:myapp, :weather_req_options, []))
        |> Req.request()
      end
    end

We configure it for production:

    # config/runtime.exs
    config :myapp, weather_req_options: [
      auth: {:bearer, System.fetch_env!("MYAPP_WEATHER_API_KEY")}
    ]

In tests, instead of hitting the network, we make the request against
a [plug](`Req.Steps.run_plug/1`) _stub_ named `MyApp.Weather`:

    # config/test.exs
    config :myapp, weather_req_options: [
      plug: {Req.Test, MyApp.Weather}
    ]

Now we can control our stubs **in concurrent tests**:

    use ExUnit.Case, async: true

    test "nice weather" do
      Req.Test.stub(MyApp.Weather, fn conn ->
        Req.Test.json(conn, %{"celsius" => 25.0})
      end)

      assert MyApp.Weather.get_rating("Krakow, Poland") == {:ok, :nice}
    end

## Concurrency and Allowances

The example above works in concurrent tests because `MyApp.Weather.get_rating/1` calls
directly to `Req.request/1` *in the same process*. It also works in many cases where the
request happens in a spawned process, such as a `Task`, `GenServer`, and more.

However, if you are encountering issues with stubs not being available in spawned processes,
it's likely that you'll need **explicit allowances**. For example, if
`MyApp.Weather.get_rating/1` was calling `Req.request/1` in a process spawned with `spawn/1`,
the stub would not be available in the spawned process:

    # With code like this, the stub would not be available in the spawned task:
    def get_rating_async(location) do
      spawn(fn -> get_rating(location) end)
    end

To make stubs defined in the test process available in other processes, you can use
`allow/3`. For example, imagine that the call to `MyApp.Weather.get_rating/1`
was happening in a spawned GenServer:

    test "nice weather" do
      {:ok, pid} = start_gen_server(...)

      Req.Test.stub(MyApp.Weather, fn conn ->
        Req.Test.json(conn, %{"celsius" => 25.0})
      end)

      Req.Test.allow(MyApp.Weather, self(), pid)

      assert get_weather(pid, "Krakow, Poland") == {:ok, :nice}
    end

## Broadway

If you're using `Req.Test` with [Broadway](https://hex.pm/broadway), you may need to use
`allow/3` to make stubs available in the Broadway processors. A great way to do that is
to hook into the [Telemetry](https://hex.pm/telemetry) events that Broadway publishes to
manually allow the processors and batch processors to access the stubs. This approach is
similar to what is [documented in Broadway
itself](https://hexdocs.pm/broadway/Broadway.html#module-testing-with-ecto).

First, you should add the test PID (which is allowed to use the Req stub) to the metadata
for the test events you're publishing:

    Broadway.test_message(MyApp.Pipeline, message, metadata: %{req_stub_owner: self()})

Then, you'll need to define a test helper to hook into the Telemetry events. For example,
in your `test/test_helper.exs` file:

    defmodule BroadwayReqStubs do
      def attach(stub) do
        events = [
          [:broadway, :processor, :start],
          [:broadway, :batch_processor, :start],
        ]

        :telemetry.attach_many({__MODULE__, stub}, events, &__MODULE__.handle_event/4, %{stub: stub})
      end

      def handle_event(_event_name, _event_measurement, %{messages: messages}, %{stub: stub}) do
        with [%Broadway.Message{metadata: %{req_stub_owner: pid}} | _] <- messages do
          :ok = Req.Test.allow(stub, pid, self())
        end

        :ok
      end
    end

Last but not least, attach the helper in your `test/test_helper.exs`:

    BroadwayReqStubs.attach(MyStub)

## redirect/2

Sends redirect response to the given url.

This function is adapted from [`Phoenix.Controller.redirect/2`](https://hexdocs.pm/phoenix/Phoenix.Controller.html#redirect/2).

For security, `:to` only accepts paths. Use the `:external`
option to redirect to any URL.

The response will be sent with the status code defined within
the connection, via `Plug.Conn.put_status/2`. If no status
code is set, a 302 response is sent.

## Examples


    iex> plug = fn
    ...>   conn when conn.request_path == nil ->
    ...>     Req.Test.redirect(conn, to: "/hello")
    ...>
    ...>   conn when conn.request_path == "/hello" ->
    ...>     Req.Test.text(conn, "Hello, World!")
    ...>   conn -> dbg(conn)
    ...> end
    iex>
    iex> resp = Req.get!(plug: plug, url: "http://example.com")
    # 14:53:06.101 [debug] redirecting to /hello
    iex> resp.body
    "Hello, World!"

## transport_error/2

Simulates a network transport error.

## Examples

    iex> plug = fn conn ->
    ...>   Req.Test.transport_error(conn, :timeout)
    ...> end
    iex>
    iex> Req.get(plug: plug, retry: false)
    {:error, %Req.TransportError{reason: :timeout}}

## stub/2

Creates a request stub with the given `name` and `plug`.

Req allows running requests against _plugs_ (instead of over the network) using the
[`:plug`](`Req.Steps.run_plug/1`) option. However, passing the `:plug` value throughout the
system can be cumbersome. Instead, you can tell Req to find plugs by `name` by setting
`plug: {Req.Test, name}`, and register plug stubs for that `name` by calling
`Req.Test.stub(name, plug)`. In other words, multiple concurrent tests can register test stubs
under the same `name`, and when Req makes the request, it will find the appropriate
implementation, even when invoked from different processes than the test process.

The `name` can be any term.

The `plug` can be one of:

  * A _function_ plug: a `fun(conn)` or `fun(conn, options)` function that takes a
    `Plug.Conn` and returns a `Plug.Conn`.

  * A _module_ plug: a `module` name or a `{module, options}` tuple.

## Examples

    iex> Req.Test.stub(MyStub, fn conn ->
    ...>   send(self(), :req_happened)
    ...>   Req.Test.json(conn, %{})
    ...> end)
    :ok
    iex> Req.get!(plug: {Req.Test, MyStub}).body
    %{}
    iex> receive do
    ...>   :req_happened -> :ok
    ...> end
    :ok

## expect/3

Creates a request expectation with the given `name` and `plug`, expected to be fetched at
most `n` times, **in order**.

This function allows you to expect a `n` number of request and handle them **in order** via the
given `plug`. It is safe to use in concurrent tests. If you fetch the value under `name` more
than `n` times, this function raises a `RuntimeError`.

The `name` can be any term.

The `plug` can be one of:

  * A _function_ plug: a `fun(conn)` or `fun(conn, options)` function that takes a
    `Plug.Conn` and returns a `Plug.Conn`.

  * A _module_ plug: a `module` name or a `{module, options}` tuple.

See `stub/2` and module documentation for more information.

`verify_on_exit!/1` can be used to ensure that all defined expectations have been called.

## Examples

Let's simulate a server that is having issues: on the first request it is not responding
and on the following two requests it returns an HTTP 500. Only on the third request it returns
an HTTP 200. Req by default automatically retries transient errors (using `Req.Steps.retry/1`)
so it will make multiple requests exercising all of our request expectations:

    iex> Req.Test.expect(MyStub, &Req.Test.transport_error(&1, :econnrefused))
    iex> Req.Test.expect(MyStub, 2, &Plug.Conn.send_resp(&1, 500, "internal server error"))
    iex> Req.Test.expect(MyStub, &Plug.Conn.send_resp(&1, 200, "ok"))
    iex> Req.get!(plug: {Req.Test, MyStub}).body
    # 15:57:06.309 [warning] retry: got exception, will retry in 1000ms, 3 attempts left
    # 15:57:06.309 [warning] ** (Req.TransportError) connection refused
    # 15:57:07.310 [warning] retry: got response with status 500, will retry in 2000ms, 2 attempts left
    # 15:57:09.311 [warning] retry: got response with status 500, will retry in 4000ms, 1 attempt left
    "ok"

    iex> Req.request!(plug: {Req.Test, MyStub})
    ** (RuntimeError) no mock or stub for MyStub

## allow/3

Allows `pid_to_allow` to access `name` provided that `owner` is already allowed.

## set_req_test_to_shared/1

Sets the `Req.Test` mode to "global", meaning that the stubs are shared across all tests
and cannot be used concurrently.

## set_req_test_to_private/1

Sets the `Req.Test` mode to "private", meaning that stubs can be shared across
tests concurrently.

## set_req_test_from_context/1

Sets the `Req.Test` mode based on the given `ExUnit` context.

This works as a ExUnit callback:

    setup :set_req_test_from_context

## verify_on_exit!/1

Sets a ExUnit callback to verify the expectations on exit.

Similar to calling `verify!/0` at the end of your test.

This works as a ExUnit callback:

    setup {Req.Test, :verify_on_exit!}

## verify!/0

Verifies that all the plugs expected to be executed within any scope have been executed.

## verify!/1

Verifies that all the plugs expected to be executed within the scope of `name` have been
executed.