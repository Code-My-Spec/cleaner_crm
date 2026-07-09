# Oban



## __using__/1

Creates a facade for `Oban` functions and automates fetching configuration from the application
environment.

Facade modules support configuration via the application environment under an OTP application
key that you specify with `:otp_app`. For example, to define a facade:

    defmodule MyApp.Oban do
      use Oban, otp_app: :my_app
    end

Then, you can configure the facade with:

    config :my_app, MyApp.Oban, repo: MyApp.Repo

Then you can include `MyApp.Oban` in your application's supervision tree without passing extra
options:

    defmodule MyApp.Application do
      use Application

      def start(_type, _args) do
        children = [
          MyApp.Repo,
          MyApp.Oban
        ]

        opts = [strategy: :one_for_one, name: MyApp.Supervisor]
        Supervisor.start_link(children, opts)
      end
    end

## Calling Functions

Facade modules allow you to call `Oban` functions on instances with custom names (rather than
`Oban`), without passing a `t:Oban.name/0` as the first argument.

For example:

    # Instead of:
    Oban.config(MyApp.Oban)

    # You can do:
    MyApp.Oban.config()

Facades also make piping into Oban functions far more convenient:

    %{some: :args}
    |> MyWorker.new()
    |> MyOban.insert()

## Merging Configuration

All configuration can be provided through the `use` macro or through the application
configuration, and options from the application supersedes those passed through `use`.
Configuration is prioritized in this order:

1. Options passed through `use`
2. Options pulled from the OTP app specified by `:otp_app` via `Application.get_env/3`
3. Options passed through a child spec in the supervisor

## start_link/1

Starts an `Oban` supervision tree linked to the current process.

## Options

These options are required; without them the supervisor won't start:

* `:repo` — specifies the Ecto repo used to insert and retrieve jobs

### Primary Options

These options determine what the system does at a high level, i.e. which queues to run:

* `:engine` — facilitates inserting, fetching, and otherwise managing jobs.

  There are three built-in engines: `Oban.Engines.Basic` for Postgres databases,
  `Oban.Engines.Lite` for SQLite3 databases, and `Oban.Engines.Inline` for simplified testing
  (only available for `:inline` testing mode).

  When the `Oban.Engines.Lite` engine is used the `:notifier` and `:peer` are automatically set
  to `PG` and `isolated` mode, respectively.

  Additional engines, such as Oban Pro's `SmartEngine` with advanced functionality for Postgres,
  are also available as an add-on.

  Defaults to the `Basic` engine for Postgres.

* `:log` — either `false` to disable logging or a standard log level (`:error`, `:warning`,
  `:info`, `:debug`, etc.). This determines whether queries are logged or not; overriding the
  repo's configured log level. Defaults to `false`, where no queries are logged.

* `:name` — used for supervisor registration, it must be unique across an entire VM instance.
  Defaults to `Oban` when no name is provided.

* `:node` — used to identify the node that the supervision tree is running in. If no value is
  provided it will use the `node` name in a distributed system, or the `hostname` in an isolated
  node. See "Node Name" below.

* `:notifier` — used to relay messages between processes, nodes, and the Postgres database.

  There are two built-in notifiers: `Oban.Notifiers.Postgres`, which uses Postgres PubSub; and
  `Oban.Notifiers.PG`, which uses process groups with distributed erlang. Defaults to the
  Postgres notifier.

* `:peer` — used to specify which peer module to use for cluster leadership.

  There are two built-in peers: `Oban.Peers.Database`, which uses table-based leadership through
  the `oban_peers` table; and `Oban.Peers.Global`, which uses global locks through distributed Erlang.

  Leadership can be disabled by setting `peer: false`, but note that centralized plugins like
  `Cron` won't run without leadership.

  Defaults to the `Database` peer.

* `:plugins` — a list or modules or module/option tuples that are started as children of an Oban
  supervisor. Any supervisable module is a valid plugin, i.e. a `GenServer` or an `Agent`. May
  also be set to `false` to disable plugins _and_ disable leadership.

* `:prefix` — the query prefix, or schema, to use for inserting and executing jobs. An
  `oban_jobs` table must exist within the prefix. See the "Prefix Support" section in the module
  documentation for more details.

* `:queues` — a keyword list where the keys are queue names and the values are the concurrency
  setting or a keyword list of queue options. For example, setting queues to `[default: 10,
  exports: 5]` would start the queues `default` and `exports` with a combined concurrency level
  of 15. The concurrency setting specifies how many jobs _each queue_ will run concurrently.

  Queues accept additional override options to customize their behavior, e.g. by setting
  `paused` or `dispatch_cooldown` for a specific queue.

  Using an empty list or `false` prevents any queues from starting on init.

* `:testing` — a mode that controls how an instance is configured for testing. When set to
  `:inline` or `:manual` queues, peers, and plugins are automatically disabled. Defaults to
  `:disabled`, no test mode.

### Twiddly Options

Additional options used to tune system behaviour. These are primarily useful for testing or
troubleshooting and don't usually need modification.

* `:dispatch_cooldown` — the average number of milliseconds a producer will wait before
  fetching and running more jobs. A cooldown period prevents a producer from flooding with
  messages and thrashing the database. Jitter is applied so that the actual wait varies between
  roughly `0` and `2x` the configured value, which prevents producers from synchronizing their
  fetches and stampeding the database.

  The cooldown period _directly impacts_ a producer's throughput: average jobs per second for a
  single queue is approximately `(1000 / cooldown) * limit`. For example, with a `5ms` cooldown
  and a queue limit of `25` a single queue averages 5,000 jobs/sec.

  The default is `5ms` and the minimum is `1ms`, which is likely faster than the database can
  return new jobs to run.

* `:insert_trigger` — whether to dispatch notifications to relevant queues as jobs are inserted
  into the database. At high load, e.g. thousands or more job inserts per second, notifications
  may become a bottleneck.

  The trigger mechanism is designed to make jobs execute immediately after insert, rather than
  up to `:stage_interval` (1 second) afterwards, and it can safely be disabled to improve insert
  throughput.

  Defaults to `true`, with triggering enabled.

* `:shutdown_grace_period` — the amount of time a queue will wait for executing jobs to complete
  before hard shutdown, specified in milliseconds. The default is `15_000`, or 15 seconds.

* `:stage_interval` — the number of milliseconds between making scheduled jobs available and
  notifying relevant queues that jobs are available. This is directly tied to the resolution of
  `scheduled` or `retryable` jobs and how frequently the database is checked for jobs to run. To
  minimize database load, only `5_000` jobs are staged at each interval.

  Only the leader node stages jobs and notifies queues when the `:notifier's` pubsub
  notifications are functional. If pubsub messages can't get through then staging switches to a
  less efficient "local" mode in which all nodes poll for jobs to run.

  Setting the interval to `:infinity` disables staging entirely. The default is `1_000ms`.

## Example

Start a stand-alone `Oban` instance:

    {:ok, pid} = Oban.start_link(repo: MyApp.Repo, queues: [default: 10])

To start an `Oban` instance within an application's supervision tree:

    def start(_type, _args) do
      children = [MyApp.Repo, {Oban, repo: MyApp.Repo, queues: [default: 10]}]

      Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)
    end

Start multiple, named `Oban` supervisors within a supervision tree:

      children = [
        MyApp.Repo,
        {Oban, name: Oban.A, repo: MyApp.Repo, queues: [default: 10]},
        {Oban, name: Oban.B, repo: MyApp.Repo, queues: [special: 10]},
      ]

      Supervisor.start_link(children, strategy: :one_for_one, name: MyApp.Supervisor)

Start a local `Oban` instance for SQLite:

    {:ok, pid} = Oban.start_link(engine: Oban.Engines.Lite, repo: MyApp.Repo)

## Node Name

When the `node` value has not been configured it is generated based on the environment:

1. If the local node is alive (e.g. in a distributed system, or when running from a mix release)
   the node name is used
2. In a Heroku environment the system environment's `DYNO` value is used
3. Otherwise, the system hostname is used

When running a mix release on a Heroku node, the node is alive even if not part of a
distributed system. In order to use the `DYNO` value, configure the node value using runtime
configuration via `config/runtime.exs`:

      config :my_app, Oban,
        node: System.get_env("DYNO", "nonode@nohost")

## whereis/1

Returns the pid of the root Oban process for the given name.

## Example

Find the default instance:

    Oban.whereis(Oban)

Find a dynamically named instance:

    Oban.whereis({:oban, 1})

## config/1

Retrieve the `Oban.Config` struct for a named Oban supervision tree.

## Example

Retrieve the default `Oban` instance config:

    %Oban.Config{} = Oban.config()

Retrieve the config for an instance started with a custom name:

    %Oban.Config{} = Oban.config(MyCustomOban)

## insert/3

Insert a new job into the database for execution.

This and the other `insert` variants are the recommended way to enqueue jobs because they
support features like unique jobs.

See the section on "Unique Jobs" for more details.

## Example

Insert a single job:

    {:ok, job} = Oban.insert(MyApp.Worker.new(%{id: 1}))

Insert a job while ensuring that it is unique within the past 30 seconds:

    {:ok, job} = Oban.insert(MyApp.Worker.new(%{id: 1}, unique: [period: 30]))

Insert a job using a custom timeout:

    {:ok, job} = Oban.insert(MyApp.Worker.new(%{id: 1}), timeout: 10_000)

Insert a job using an alternative instance name:

    {:ok, job} = Oban.insert(MyOban, MyApp.Worker.new(%{id: 1}))

## insert/5

Put a job insert operation into an `Ecto.Multi`.

Like `insert/2`, this variant is recommended over `Ecto.Multi.insert` because it supports all of
Oban's features, i.e. unique jobs.

See the section on "Unique Jobs" for more details.

## Example

    Ecto.Multi.new()
    |> Oban.insert("job-1", MyApp.Worker.new(%{id: 1}))
    |> Oban.insert("job-2", fn _ -> MyApp.Worker.new(%{id: 2}) end)
    |> MyApp.Repo.transaction()

## insert!/3

Similar to `insert/3`, but raises an `Ecto.InvalidChangesetError` if the job can't be inserted.

## Example

Insert a single job:

    job = Oban.insert!(MyApp.Worker.new(%{id: 1}))

Insert a job using a custom timeout:

    job = Oban.insert!(MyApp.Worker.new(%{id: 1}), timeout: 10_000)

Insert a job using an alternative instance name:

    job = Oban.insert!(MyOban, MyApp.Worker.new(%{id: 1}))

## insert_all/3

Insert multiple jobs into the database for execution.

There are a few important differences between this function and `c:Ecto.Repo.insert_all/3`:

1. This function always returns a list rather than a tuple of `{count, records}`
2. This function accepts a list of changesets rather than a list of maps or keyword lists

#### Error Handling and Rollbacks

If `insert_all` encounters an issue, the function will raise an error based on your database
adapter. This behavior is valuable in conjunction with `c:Ecto.Repo.transaction/2` because it
allows for rollbacks.

For example, an invalid changeset raises:

`* (Ecto.InvalidChangesetError) could not perform insert because changeset is invalid.`

#### Dolphin Engine and Generated Values

MySQL doesn't return anything on insertion into the database. That means any values generated by
the database, namely the primary key and timestamps, aren't included in the job structs returned
from `insert_all`.

> #### 🌟 Unique Jobs and Batching {: .tip}
>
> Only the [Smart Engine](https://oban.pro/docs/pro/Oban.Pro.Engines.Smart.html) in [Oban
> Pro](https://oban.pro) supports bulk unique jobs, automatic insert batching, and minimizes
> parameters sent over the wire. With the basic engine, you must use `insert/3` to insert unique
> jobs one at a time.

## Options

Accepts any of Ecto's "Shared Options" such as `timeout` and `log`.

## Example

Insert a list of 100 jobs at once:

    1..100
    |> Enum.map(&MyApp.Worker.new(%{id: &1}))
    |> Oban.insert_all()

Insert a stream of jobs at once (be sure the stream terminates!):

    (fn -> MyApp.Worker.new(%{}))
    |> Stream.repeatedly()
    |> Stream.take(100)
    |> Oban.insert_all()

Insert with a custom timeout:

    1..100
    |> Enum.map(&MyApp.Worker.new(%{id: &1}))
    |> Oban.insert_all(timeout: 10_000)

Insert with an alternative instance name:

    changesets = Enum.map(1..100, &MyApp.Worker.new(%{id: &1}))
    jobs = Oban.insert_all(MyOban, changesets)

## insert_all/5

Put an `insert_all` operation into an `Ecto.Multi`.

This function supports the same features and has the same caveats as `insert_all/2`.

## Example

Insert job changesets within a multi:

    changesets = Enum.map(0..100, &MyApp.Worker.new(%{id: &1}))

    Ecto.Multi.new()
    |> Oban.insert_all(:jobs, changesets)
    |> MyApp.Repo.transaction()

Insert job changesets using a function:

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, user_changeset)
    |> Oban.insert_all(:jobs, fn %{user: user} ->
      email_job = EmailWorker.new(%{id: user.id})
      staff_job = StaffWorker.new(%{id: user.id})
      [email_job, staff_job]
    end)
    |> MyApp.Repo.transaction()

## drain_queue/2

Synchronously execute all available jobs in a queue.

All execution happens within the current process and it is guaranteed not to raise an error or
exit.

Draining a queue from within the current process is especially useful for testing. Jobs that are
enqueued by a process when `Ecto` is in sandbox mode are only visible to that process. Calling
`drain_queue/2` allows you to control when the jobs are executed and to wait synchronously for
all jobs to complete.

## Failures & Retries

Draining a queue uses the same execution mechanism as regular job dispatch. That means that any
job failures or crashes are captured and result in a retry. Retries are scheduled in the future
with backoff and won't be retried immediately.

By default jobs are executed in `safe` mode, just as they are in production. Safe mode catches
any errors or exits and records the formatted error in the job's `errors` array.  That means
exceptions and crashes are _not_ bubbled up to the calling process.

If you expect jobs to fail, would like to track failures, or need to check for specific errors
you can pass the `with_safety: false` flag. See the "Options" section below for more details.

## Scheduled Jobs

By default, `drain_queue/2` will execute all currently available jobs. In order to execute
scheduled jobs, you may pass the `with_scheduled: true` which will cause all scheduled jobs to
be marked as `available` beforehand. To run jobs scheduled up to a specific point in time, pass
a `DateTime` instead.

## Options

* `:queue` - a string or atom specifying the queue to drain, required

* `:with_limit` — the maximum number of jobs to drain at once. When recursion is enabled this is
  how many jobs are processed per-iteration.

* `:with_recursion` — whether to keep draining a queue repeatedly when jobs insert _more_ jobs

* `:with_safety` — whether to silently catch errors when draining, defaults to `true`. When
  `false`, raised exceptions or unhandled exits are reraised (unhandled exits are wrapped in
  `Oban.CrashError`).

* `:with_scheduled` — whether to include any scheduled jobs when draining, default `false`.
   When `true`, drains all scheduled jobs. When a `DateTime` is provided, drains all jobs
   scheduled up to, and including, that point in time.

## Example

Drain a queue with three available jobs, two of which succeed and one of which fails:

    Oban.drain_queue(queue: :default)
    %{failure: 1, snoozed: 0, success: 2}

Drain a queue including any scheduled jobs:

    Oban.drain_queue(queue: :default, with_scheduled: true)
    %{failure: 0, snoozed: 0, success: 1}

Drain a queue including jobs scheduled up to a minute:

    Oban.drain_queue(queue: :default, with_scheduled: DateTime.add(DateTime.utc_now(), 60, :second))

Drain a queue and assert an error is raised:

    assert_raise RuntimeError, fn -> Oban.drain_queue(queue: :risky, with_safety: false) end

Drain a queue repeatedly until there aren't any more jobs to run. This is particularly useful
for testing jobs that enqueue other jobs:

    Oban.drain_queue(queue: :default, with_recursion: true)
    %{failure: 1, snoozed: 0, success: 2}

Drain only the top (by scheduled time and priority) five jobs off a queue:

    Oban.drain_queue(queue: :default, with_limit: 5)
    %{failure: 0, snoozed: 0, success: 1}

Drain a queue recursively, only one job at a time:

    Oban.drain_queue(queue: :default, with_limit: 1, with_recursion: true)
    %{failure: 0, snoozed: 0, success: 3}

## start_queue/2

Start a new supervised queue.

By default this starts a new supervised queue across all nodes running Oban on the same database
and prefix. You can pass the option `local_only: true` if you prefer to start the queue only on
the local node.

## Options

* `:queue` - a string or atom specifying the queue to start, required
* `:local_only` - whether the queue will be started only on the local node, default: `false`
* `:limit` - set the concurrency limit, required
* `:paused` — set whether the queue starts in the "paused" state, optional

In addition, all engine-specific queue options are passed along after validation.

## Example

Start the `:priority` queue with a concurrency limit of 10 across the connected nodes.

    Oban.start_queue(queue: :priority, limit: 10)
    :ok

Start the `:media` queue with a concurrency limit of 5 only on the local node.

    Oban.start_queue(queue: :media, limit: 5, local_only: true)
    :ok

Start the `:media` queue on a particular node.

    Oban.start_queue(queue: :media, limit: 5, node: "worker.1")
    :ok

Start the `:media` queue in a `paused` state.

    Oban.start_queue(queue: :media, limit: 5, paused: true)
    :ok

## pause_queue/2

Pause a running queue, preventing it from executing any new jobs. All running jobs will remain
running until they are finished.

When shutdown begins all queues are paused.

## Options

* `:queue` - a string or atom specifying the queue to pause, required

* `:local_only` - whether the queue will be paused only on the local node, default: `false`

* `:node` - restrict pausing to a particular node

Note: by default, Oban does not verify that the given queue exists unless `:local_only`
is set to `true` as even if the queue does not exist locally, it might be running on
another node.

## Example

Pause the default queue:

    Oban.pause_queue(queue: :default)
    :ok

Pause the default queue, but only on the local node:

    Oban.pause_queue(queue: :default, local_only: true)
    :ok

Pause the default queue only on a particular node:

    Oban.pause_queue(queue: :default, node: "worker.1")
    :ok

## pause_all_queues/2

Pause all running queues to prevent them from executing any new jobs.

See `pause_queue/2` for options and details.

## Example

Pause all queues:

    Oban.pause_all_queues()

Pause all queues on the local node:

    Oban.pause_all_queues(local_only: true)

Pause all queues on a specific node:

    Oban.pause_all_queues(node: "worker.1")

Pause all queues for an alternative instance name:

    Oban.pause_all_queues(MyOban)

## resume_queue/2

Resume executing jobs in a paused queue.

## Options

* `:queue` - a string or atom specifying the queue to resume, required

* `:local_only` - whether the queue will be resumed only on the local node, default: `false`

* `:node` - restrict resuming to a particular node

Note: by default, Oban does not verify that the given queue exists unless `:local_only`
is set to `true` as even if the queue does not exist locally, it might be running on
another node.

## Example

Resume a paused default queue:

    Oban.resume_queue(queue: :default)

Resume the default queue, but only on the local node:

    Oban.resume_queue(queue: :default, local_only: true)

Resume the default queue only on a particular node:

    Oban.resume_queue(queue: :default, node: "worker.1")

## resume_all_queues/2

Resume executing jobs in all paused queues.

See `resume_queue/2` for options and details.

## Example

Resume all queues:

    Oban.resume_all_queues()

Resume all queues on the local node:

    Oban.resume_all_queues(local_only: true)

Resume all queues on a specific node:

    Oban.resume_all_queues(node: "worker.1")

Resume all queues for an alternative instance name:

    Oban.resume_all_queues(MyOban)

## scale_queue/2

Scale the concurrency for a queue.

## Options

* `:queue` - a string or atom specifying the queue to scale, required

* `:limit` — the new concurrency limit, required

* `:local_only` — whether the queue will be scaled only on the local node, default: `false`

* `:node` - restrict scaling to a particular node

In addition, all engine-specific queue options are passed along after validation.

Note: by default, Oban does not verify that the given queue exists unless `:local_only`
is set to `true` as even if the queue does not exist locally, it might be running on
another node.

## Example

Scale a queue up, triggering immediate execution of queued jobs:

    Oban.scale_queue(queue: :default, limit: 50)
    :ok

Scale the queue back down, allowing executing jobs to finish:

    Oban.scale_queue(queue: :default, limit: 5)
    :ok

Scale the queue only on the local node:

    Oban.scale_queue(queue: :default, limit: 10, local_only: true)
    :ok

Scale the queue on a particular node:

    Oban.scale_queue(queue: :default, limit: 10, node: "worker.1")
    :ok

## stop_queue/2

Shutdown a queue's supervision tree and stop running jobs for that queue.

By default this action will occur across all the running nodes. Still, if you prefer to stop the
queue's supervision tree and stop running jobs for that queue only on the local node, you can
pass the option: `local_only: true`

The shutdown process pauses the queue first and allows current jobs to exit gracefully, provided
they finish within the shutdown limit.

Note: by default, Oban does not verify that the given queue exists unless `:local_only`
is set to `true` as even if the queue does not exist locally, it might be running on
another node.

## Options

* `:queue` - a string or atom specifying the queue to stop, required

* `:local_only` - whether the queue will be stopped only on the local node, default: `false`

* `:node` - restrict stopping to a particular node

## Example

Stop a running queue on all nodes:

    Oban.stop_queue(queue: :default)
    :ok

Stop the queue only on the local node:

    Oban.stop_queue(queue: :media, local_only: true)
    :ok

Stop the queue only on a particular node:

    Oban.stop_queue(queue: :media, node: "worker.1")
    :ok

## check_queue/2

Check the current state of a queue producer.

This allows you to introspect on a queue's health by retrieving key attributes of the producer's
state; values such as the current `limit`, the `running` job ids, and when the producer was
started.

## Options

* `:queue` - a string or atom specifying the queue to check, required

## Example

Get details about the `default` queue:

    Oban.check_queue(queue: :default)
    %{
      limit: 10,
      node: "me@local",
      paused: false,
      queue: "default",
      running: [100, 102],
      started_at: ~D[2020-10-07 15:31:00],
      updated_at: ~D[2020-10-07 15:31:00]
    }

Attempt to get details about a queue that isn't running locally:

    Oban.check_queue(queue: :not_really_running)
    nil

## check_all_queues/1

Check the current state of all queue producers.

## Example

Get information about all running queues for the default instance:

    Enum.map(Oban.check_all_queues(), &Map.take(&1, [:queue, :limit]))
    [%{queue: "default", limit: 10}, %{queue: "other", limit: 5}]

Get information for an alternate instance:

    Oban.check_all_queues(Other.Oban)

## retry_job/2

Sets a job as `available`, adding attempts if already maxed out. Jobs currently `available` or
`executing` are ignored. The job is scheduled for immediate execution.

## Example

Retry a job:

    Oban.retry_job(job)
    :ok

## retry_all_jobs/2

Retries all jobs that match on the given queryable.

If no queryable is given, Oban will retry all jobs that aren't currently `available` or
`executing`. Note that regardless of constraints, it will never retry `available` or
`executing` jobs.

## Example

Retries jobs in _any state_ other than `available` or `executing`:

    Oban.retry_all_jobs(Oban.Job)
    {:ok, 9}

Retries jobs with the `retryable` state:

    [state: :retryable]
    |> Oban.Job.query()
    |> Oban.retry_all_jobs()
    {:ok, 3}

Retries all inactive jobs with priority 0:

    [priority: 0]
    |> Oban.Job.query()
    |> Oban.retry_all_jobs()
    {:ok, 5}

## cancel_job/2

Cancel an `executing`, `available`, `scheduled` or `retryable` job and mark it as `cancelled` to
prevent it from running. If the job is currently `executing` it will be killed and otherwise it
is ignored.

If an executing job happens to fail before it can be cancelled the state is set to `cancelled`.
However, if it manages to complete successfully then the state will still be `completed`.

## Example

Cancel a job:

    Oban.cancel_job(job)
    :ok

Cancel a job for a custom instance:

    Oban.cancel_job(MyOban, job)
    :ok

## all_jobs/2

Fetch all jobs matching a queryable.

The `queryable` is typically `Oban.Job` or an `Ecto.Query` built from it, for example via
`Oban.Job.query/1` or direct `Ecto.Query` composition. Jobs are loaded through the repo
configured for the given instance.

## Examples

Fetch every job:

    Oban.all_jobs(Oban.Job)

Fetch jobs matching a set of filters:

    [state: ~w(available scheduled), worker: MyApp.Worker]
    |> Oban.Job.query()
    |> Oban.all_jobs()

Fetch jobs from a custom instance:

    Oban.all_jobs(MyOban, Oban.Job)

## cancel_all_jobs/2

Cancel many jobs based on a queryable and mark them as `cancelled` to prevent them from running.

Any currently `executing` jobs are killed. If executing jobs happen to fail before cancellation
then the state is set to `cancelled`. However, any that complete successfully will remain
`completed`.

Only jobs with the statuses `executing`, `available`, `scheduled`, or `retryable` can be cancelled.

## Example

Cancel all jobs:

    Oban.cancel_all_jobs(Oban.Job)
    {:ok, 9}

Cancel all jobs for a specific worker:

    [worker: MyApp.MyWorker]
    |> Oban.Job.query()
    |> Oban.cancel_all_jobs()
    {:ok, 2}

## delete_job/2

Delete a job that's not currently `executing`.

## Example

Delete a job:

    Oban.delete_job(job)
    :ok

Delete a job for a custom instance:

    Oban.delete_job(MyOban, job)
    :ok

## delete_all_jobs/2

Delete many jobs based on a queryable.

Only jobs that aren't `executing` may be deleted.

## Example

Delete all jobs for a specific worker:

    [worker: MyApp.MyWorker]
    |> Oban.Job.query()
    |> Oban.delete_all_jobs()
    {:ok, 9}

## update_job/3

Update a job with the given changes.

This function accepts either a job struct or id, along with either a map of changes or a
function that receives the job and returns a map of changes.

The update operation is wrapped in a transaction with a locking clause (when available) to
prevent concurrent modifications.

### Fields and Validations

All changes are validated using the same validations as `insert/2`. Only the following subset of
fields can be updated:

* `:args`
* `:max_attempts`
* `:meta`
* `:priority`
* `:queue`
* `:scheduled_at`
* `:tags`
* `:worker`

> #### Updating Executing Jobs {: .warning}
>
> Use caution when updating jobs that are currently `executing`. Modifying fields like `:args`,
> `:queue`, or `:worker` while a job is running may lead to unexpected behavior or inconsistent
> state. Consider whether the job should be cancelled first, or if the update should be deferred
> until after execution completes.

## Examples

Update a job with a map of changes:

    Oban.update_job(job, %{tags: ["urgent"], priority: 0})

Update a job by id:

    Oban.update_job(123, %{tags: ["processed"], meta: %{batch_id: 456}})

Update a job using a function:

    Oban.update_job(job, fn job -> %{tags: ["retry" | job.tags]} end)

Using a named Oban instance:

    Oban.update_job(MyApp.Oban, job, fn job ->
      %{meta: Map.put(job.meta, "processed_at", DateTime.utc_now())}
    end)