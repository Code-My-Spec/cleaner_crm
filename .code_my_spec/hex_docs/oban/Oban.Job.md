# Oban.Job

A Job is an Ecto schema used for asynchronous execution.

Job changesets are created by your application code and inserted into the database for
asynchronous execution. Jobs can be inserted along with other application data as part of a
transaction, which guarantees that jobs will only be triggered from a successful transaction.

## new/2

Construct a new job changeset ready for insertion into the database.

## Options

  * `:max_attempts` — the maximum number of times a job can be retried if there are errors
    during execution

  * `:meta` — a map containing additional information about the job

  * `:priority` — a numerical indicator from 0 to 9 of how important this job is relative to
    other jobs in the same queue. The lower the number, the higher priority the job.

  * `:queue` — a named queue to push the job into. Jobs may be pushed into any queue, regardless
    of whether jobs are currently being processed for the queue.

  * `:replace` - a list of keys to replace per state on a unique conflict

  * `:scheduled_at` - a time in the future after which the job should be executed

  * `:schedule_in` - the number of seconds until the job should be executed or a tuple containing
    a number and unit

  * `:tags` — a list of tags to group and organize related jobs, i.e. to identify scheduled jobs

  * `:unique` — a keyword list of options specifying how uniqueness will be calculated. The
    options define which fields will be used, for how long, with which keys, and for which states.

  * `:worker` — a module to execute the job in. The module must implement the `Oban.Worker`
    behaviour.

## Examples

Insert a job with the `:default` queue:

    %{id: 1, user_id: 2}
    |> Oban.Job.new(queue: :default, worker: MyApp.Worker)
    |> Oban.insert()

Generate a pre-configured job for `MyApp.Worker`:

    MyApp.Worker.new(%{id: 1, user_id: 2})

Schedule a job to run in 5 seconds:

    MyApp.Worker.new(%{id: 1}, schedule_in: 5)

Schedule a job to run in 5 minutes:

    MyApp.Worker.new(%{id: 1}, schedule_in: {5, :minutes})

Insert a job, ensuring that it is unique within the past minute:

    MyApp.Worker.new(%{id: 1}, unique: [period: {1, :minute}])

Insert a unique job where the period is compared to the `scheduled_at` timestamp rather than
`inserted_at`:

    MyApp.Worker.new(%{id: 1}, unique: [period: 60, timestamp: :scheduled_at])

Insert a unique job based only on the worker field, and within multiple states:

    fields = [:worker]
    states = [:available, :scheduled, :executing, :retryable, :completed]

    MyApp.Worker.new(%{id: 1}, unique: [fields: fields, period: 60, states: states])

Insert a unique job considering only the worker and specified keys in the args:

    keys = [:account_id, :url]
    args = %{account_id: 1, url: "https://example.com"}

    MyApp.Worker.new(args, unique: [fields: [:args, :worker], keys: keys])

Insert a unique job considering only specified keys in the meta:

    unique = [fields: [:meta], keys: [:slug]]

    MyApp.Worker.new(%{id: 1}, meta: %{slug: "unique-key"}, unique: unique)

## update/2

Construct a changeset for updating an existing job with the given changes.

Only a subset of fields are allowed to be updated, and all validations from `new/2`
are applied to ensure data integrity.

## Examples

Update the tags and priority of a job:

    Oban.Job.update(job, %{tags: ["urgent"], priority: 5})

## states/0

A canonical list of all possible job states.

This may be used to build up `:unique` options without duplicating states in application code.

## Examples

    iex> Oban.Job.states() -- [:completed, :discarded]
    ~w(suspended scheduled available executing retryable cancelled)a

## Job State Transitions

* `:suspended`—Jobs that are held and won't be processed until they are resumed

* `:scheduled`—Jobs inserted with `scheduled_at` in the future are `:scheduled`. After the
  `scheduled_at` time has elapsed Oban's job staging will transition them to `:available`

* `:available`—Jobs without a future `scheduled_at` timestamp are inserted as `:available` and may
  execute immediately

* `:executing`—Available jobs may be ran, at which point they are `:executing`

* `:retryable`—Jobs that fail and haven't exceeded their max attempts are transitioned to
  `:retryable` and rescheduled until after a backoff period. Once the backoff has elapsed
  Oban's job staging will transition them back to `:available`

* `:completed`—Jobs that finish executing succesfully are marked `:completed`

* `:cancelled`—Jobs that are cancelled intentionally

* `:discarded`—Jobs that fail and exhaust their max attempts, or return a `:discard` tuple during
  execution, are marked `:discarded`

## unique_states/1

A list of job states tailored to uniqueness constraints.

## Named Groups

* `:all` - All possible job states
* `:incomplete` - States for jobs that haven't completed processing
* `:scheduled` - Only scheduled jobs
* `:successful` - Jobs that aren't cancelled or discarded (default)

## Examples

    iex> Oban.Job.unique_states(:incomplete)
    ~w(suspended available scheduled executing retryable)a

    iex> Oban.Job.unique_states(:scheduled)
    ~w(scheduled)a

## query/1

Build a composable query over `Oban.Job` from a keyword list of filters.

* Scalar values become equality matches
* List values become `IN` matches, except the `:tags` field, which is always compared as a
  complete array
* Atom values are coerced to strings for `:state` and `:queue`, and modules are coerced for
  `:worker`.
* Map values for `:args` and `:meta` become JSONB containment matches, with nested maps and
  multiple keys supported natively. Only Postgres is supported; SQLite and MySQL users should
  compose JSON filters with `Ecto.Query` directly.
* Unknown fields, `nil` values, empty lists (except on `:tags`), and empty maps will raise an
  `ArgumentError`.

The return value is an `Ecto.Queryable` that can be piped into further `Ecto.Query` composition
or passed to functions like `Oban.cancel_all_jobs/2` and `Oban.delete_all_jobs/2`.

## Examples

Match a single field:

    Oban.Job.query(state: "completed")

Match multiple values in a field:

    Oban.Job.query(state: ~w(completed cancelled))

Combine multiple filters:

    Oban.Job.query(worker: MyApp.Worker, state: :available, queue: :default)

Match against `args` or `meta` with JSONB containment:

    Oban.Job.query(args: %{account_id: 1})
    Oban.Job.query(args: %{account_id: 1, region: "us-east"})
    Oban.Job.query(args: %{user: %{id: 42}})

Compose with further `Ecto.Query` calls:

    import Ecto.Query

    [state: :available]
    |> Oban.Job.query()
    |> order_by(desc: :id)
    |> limit(100)

## to_map/1

Convert a Job changeset into a map suitable for database insertion.

## Examples

Convert a worker generated changeset into a plain map:

    %{id: 123}
    |> MyApp.Worker.new()
    |> Oban.Job.to_map()

## format_attempt/1

Normalize, blame, and format a job's `unsaved_error` into the stored error format.

Formatted errors are stored in a job's `errors` field.