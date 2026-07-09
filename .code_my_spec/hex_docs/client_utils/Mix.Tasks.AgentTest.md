# Mix.Tasks.AgentTest

Runs mix test with a lock file to prevent concurrent test runs.
Queued requests block until their results are ready.

## Usage

    mix agent_test [options]

All arguments are passed through to `mix test`.

## Examples

    mix agent_test
    mix agent_test test/my_test.exs
    mix agent_test --only integration