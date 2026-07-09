# Credo.Execution.ExecutionTiming

The `ExecutionTiming` module can help in timing the execution of code parts and
storing those timing inside the `Credo.Execution` struct.

## inspect/2

Runs the given `fun` and prints the time it took with the given `label`.

    iex> Credo.Execution.ExecutionTiming.inspect("foo", fn -> some_complicated_stuff() end)
    foo: 51284

## now/0

Returns the current timestamp in the same format (microseconds) as the returned starting times of `run/1`.

## run/1

Runs the given `fun` and returns a tuple of `{started_at, duration, result}`.

    iex> Credo.Execution.ExecutionTiming.run(fn -> some_complicated_stuff() end)
    {1540540119448181, 51284, [:whatever, :fun, :returned]}

## run/2

Same as `run/1` but takes `fun` and `args` separately.

## append/4

Adds a timing to the given `exec` using the given values of `tags`, `started_at` and `duration`.

## append/3

Adds a timing piped from `run/2` to the given `exec` (using the given values of `tags`, `started_at` and `duration`).

## all/1

Returns all timings for the given `exec`.

## grouped_by_tag/2

Groups all timings for the given `exec` and `tag_name`.

## by_tag/2

Returns all timings for the given `exec` and `tag_name`.

## by_tag/3

Returns all timings for the given `exec` and `tag_name` where the tag's value also matches the given `regex`.

## started_at/1

Returns the earliest timestamp for the given `exec`.

## ended_at/1

Returns the latest timestamp plus its duration for the given `exec`.