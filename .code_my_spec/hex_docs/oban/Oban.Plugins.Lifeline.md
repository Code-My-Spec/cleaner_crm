# Oban.Plugins.Lifeline

Naively transition jobs stuck `executing` back to `available`.

The `Lifeline` plugin periodically rescues orphaned jobs, i.e. jobs that are stuck in the
`executing` state because the node was shut down before the job could finish. Rescuing is
purely based on time, rather than any heuristic about the job's expected execution time or
whether the node is still alive.

If an executing job has exhausted all attempts, the Lifeline plugin will mark it `discarded`
rather than `available`.

> #### 🌟 DynamicLifeline {: .info}
>
> This plugin may transition jobs that are genuinely `executing` and cause duplicate execution.
> For more accurate rescuing or to rescue jobs that have exhausted retry attempts see the
> `DynamicLifeline` plugin in [Oban Pro](https://oban.pro/docs/pro/Oban.Pro.Plugins.DynamicLifeline.html).

## Using the Plugin

Rescue orphaned jobs that are still `executing` after the default of 60 minutes:

    config :my_app, Oban,
      plugins: [Oban.Plugins.Lifeline],
      ...

Override the default period to rescue orphans after a more aggressive period of 5 minutes:

    config :my_app, Oban,
      plugins: [{Oban.Plugins.Lifeline, rescue_after: :timer.minutes(5)}],
      ...

## Options

* `:interval` — the number of milliseconds between rescue attempts. The default is `60_000ms`.

* `:rescue_after` — the maximum amount of time, in milliseconds, that a job may execute before
being rescued. 60 minutes by default, and rescuing is performed once a minute.

## Instrumenting with Telemetry

The `Oban.Plugins.Lifeline` plugin adds the following metadata to the `[:oban, :plugin, :stop]`
event:

* `:rescued_jobs` — a list of jobs transitioned back to `available`

* `:discarded_jobs` — a list of jobs transitioned to `discarded`

_Note: jobs only include `id`, `queue`, `state` fields._