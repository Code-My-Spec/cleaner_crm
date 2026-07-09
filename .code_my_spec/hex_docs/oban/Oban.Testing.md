# Oban.Testing

This module simplifies testing workers and making assertions about enqueued jobs when testing in
`:manual` mode.

Assertions may be made on any property of a job, but you'll typically want to check by `args`,
`queue` or `worker`.

## Usage

The most convenient way to use `Oban.Testing` is to `use` the module:

    use Oban.Testing, repo: MyApp.Repo

That will define the helper functions you'll use to make assertions on the jobs that should (or
should not) be inserted in the database while testing.

If you're using namespacing through Postgres schemas, also called "prefixes" in Ecto, you
should set the `prefix` option:

    use Oban.Testing, repo: MyApp.Repo, prefix: "business"

Unless overridden, the default `prefix` is `public`.

### Adding to Case Templates

To include helpers in all of your tests you can add it to your case template:

```elixir
defmodule MyApp.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Oban.Testing, repo: MyApp.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import MyApp.DataCase

      alias MyApp.Repo
    end
  end
end
```

## Examples

After the test helpers are imported, you can make assertions about enqueued (available or
scheduled) jobs in your tests.

Here are a few examples that demonstrate what's possible:

```elixir
# Assert that a job was already enqueued
assert_enqueued worker: MyWorker, args: %{id: 1}

# Assert that a job was enqueued or will be enqueued in the next 100ms
assert_enqueued [worker: MyWorker, args: %{id: 1}], 100

# Refute that a job was already enqueued
refute_enqueued queue: "special", args: %{id: 2}

# Refute that a job was already enqueued or would be enqueued in the next 100ms
refute_enqueued queue: "special", args: %{id: 2}, 100

# Make assertions on a list of all jobs matching some options
assert [%{args: %{"id" => 1}}] = all_enqueued(worker: MyWorker)

# Assert that no jobs are enqueued in any queues
assert [] = all_enqueued()
```

Note that the final example, using `all_enqueued/1`, returns a raw list of matching jobs and
does not make an assertion by itself. This makes it possible to test using pattern matching at
the expense of being more verbose.

See the docs for `assert_enqueued/1,2`, `refute_enqueued/1,2`, and `all_enqueued/1` for more
examples.

## Matching Timestamps

In order to assert a job has been scheduled at a certain time, you will need to match against
the `scheduled_at` attribute of the enqueued job.

    in_an_hour = DateTime.add(DateTime.utc_now(), 3600, :second)
    assert_enqueued worker: MyApp.Worker, scheduled_at: in_an_hour

By default, Oban will apply a 1 second delta to all timestamp fields of jobs, so that small
deviations between the actual value and the expected one are ignored. You may configure this
delta by passing a tuple of value and a `delta` option (in seconds) to corresponding keyword:

    assert_enqueued worker: MyApp.Worker, scheduled_at: {in_an_hour, delta: 10}

## build_job/3

Construct a job from a worker, args, and options.

The helper makes the following assertions:

* That the worker implements the `Oban.Worker` behaviour
* That the options provided build a valid job

This helper is used to build jobs for execution by `perform_job/2`.

## Examples

Build a job without args:

    job = build_job(MyWorker, %{})

Build a job with stringified args:

    assert %{args: %{"id" => 1}} = build_job(MyWorker, %{id: 1})

Build a job with custom options:

    assert %{attempt: 5, priority: 9} = build_job(MyWorker, %{}, attempt: 5, priority: 9)

## perform_job/2

Execute a job using the given config options.

See `perform_job/3` for more details and examples.

## Examples

Execute a job without any options:

    assert :ok = perform_job(job, [])

Execute a job with a custom prefix and repo:

    assert :ok = perform_job(job, prefix: "private", repo: MyApp.Repo)

## perform_job/3

Construct a job and execute it with a worker module.

This reduces boilerplate when constructing jobs for unit tests and checks for common pitfalls.
For example, it automatically converts `args` to string keys before calling `perform/1`,
ensuring that perform clauses aren't erroneously trying to match atom keys.

The helper makes the following assertions:

* That the worker implements the `Oban.Worker` behaviour
* That the options provided build a valid job
* That the return is valid, e.g. `:ok`, `{:ok, value}`, `{:error, value}` etc.

If all of the assertions pass, then the function returns the result of `perform/1` for you to
make additional assertions on.

## Examples

Successfully execute a job with some string arguments:

    assert :ok = perform_job(MyWorker, %{"id" => 1})

Successfully execute a job and assert that it returns an error tuple:

    assert {:error, _} = perform_job(MyWorker, %{"bad" => "arg"})

Execute a job with the args keys automatically stringified:

    assert :ok = perform_job(MyWorker, %{id: 1})

Exercise custom attempt handling within a worker by passing options:

    assert :ok = perform_job(MyWorker, %{}, attempt: 42)

Cause a test failure because the provided worker isn't real:

    assert :ok = perform_job(Vorker, %{"id" => 1})

## all_enqueued/1

Retrieve all currently enqueued jobs matching a set of options.

Only jobs matching all of the provided arguments will be returned. Additionally, jobs are
returned in descending order where the most recently enqueued job will be listed first.

## Examples

Assert based on only _some_ of a job's args:

    assert [%{args: %{"id" => 1}}] = all_enqueued(worker: MyWorker)

Assert that exactly one job was inserted for a queue:

    assert [%Oban.Job{}] = all_enqueued(queue: :alpha)

Assert that there aren't any jobs enqueued for any queues or workers:

    assert [] = all_enqueued()

## assert_enqueued/1

Assert that a job with matching fields is enqueued.

Only values for the provided fields are checked. For example, an assertion made on `worker:
"MyWorker"` will match _any_ jobs for that worker, regardless of every other field.

## Examples

Assert that a job is enqueued for a certain worker and args:

    assert_enqueued worker: MyWorker, args: %{id: 1}

Assert that a job is enqueued for a particular queue and priority:

    assert_enqueued queue: :business, priority: 3

Assert that a job's args deeply match:

    assert_enqueued args: %{config: %{enabled: true}}

Use the `:_` wildcard to assert that a job's meta has a key with any value:

    assert_enqueued meta: %{batch_id: :_}

## assert_enqueued/2

Assert that a job with particular options is or will be enqueued within a timeout period.

See `assert_enqueued/1` for additional details.

## Examples

Assert that a job will be enqueued in the next 100ms:

    assert_enqueued [worker: MyWorker], 100

## refute_enqueued/1

Refute that a job with particular options has been enqueued.

See `assert_enqueued/1` for additional details.

## Examples

Refute that a job is enqueued for a certain worker:

    refute_enqueued worker: MyWorker

Refute that a job is enqueued for a certain worker and args:

    refute_enqueued worker: MyWorker, args: %{id: 1}

Refute that a job's nested args match:

    refute_enqueued args: %{config: %{enabled: false}}

Use the `:_` wildcard to refute that a job's meta has a key with any value:

    refute_enqueued meta: %{batch_id: :_}

## refute_enqueued/2

Refute that a job with particular options is or will be enqueued within a timeout period.

See `assert_enqueued/1` for additional details.

## Examples

Refute that a job will be enqueued in the next 100ms:

    refute_enqueued [worker: MyWorker], 100

## with_testing_mode/2

Change the testing mode within the context of a function.

Only `:manual` and `:inline` mode are supported, as `:disabled` implies that supervised queues
and plugins are running and this function won't start any processes.

## Examples

Switch to `:manual` mode when an Oban instance is configured for `:inline` testing:

    Oban.Testing.with_testing_mode(:manual, fn ->
      Oban.insert(MyWorker.new(%{id: 123}))

      assert_enqueued worker: MyWorker, args: %{id: 123}
    end)

Visa-versa, switch to `:inline` mode:

    Oban.Testing.with_testing_mode(:inline, fn ->
      {:ok, %Job{state: "completed"}} = Oban.insert(MyWorker.new(%{id: 123}))
    end)