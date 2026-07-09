# Oban.Plugins.Pruner

Periodically delete `completed`, `cancelled`, and `discarded` jobs based on their age.

Pruning is critical for maintaining table size and continued responsive job processing. It
is recommended for all production applications. See also the
[*Operational Maintenance* guide](operational_maintenance.html).

> #### 🌟 DynamicPruner {: .info}
>
> This plugin is limited to a fixed interval and a single `max_age` check for all jobs. To prune
> on a cron-style schedule, retain jobs by a limit or age, or provide overrides for specific
> queues, workers, and job states; see Oban Pro's
> [DynamicPruner](https://oban.pro/docs/pro/Oban.Pro.Plugins.DynamicPruner.html).

## Using the Plugin

The following example demonstrates using the plugin without any configuration, which will prune
jobs older than the default of 60 seconds:

    config :my_app, Oban,
      plugins: [Oban.Plugins.Pruner],
      ...

Override the default options to prune jobs after 5 minutes:

    config :my_app, Oban,
      plugins: [{Oban.Plugins.Pruner, max_age: 300}],
      ...

## Options

* `:interval` — the number of milliseconds between pruning attempts. The default is `30_000ms`.

* `:limit` — the maximum number of jobs to prune at one time. The default is 10,000 to prevent
  request timeouts. Applications that steadily generate more than 10k jobs a minute should
  increase this value.

* `:max_age` — the number of seconds after which a job may be pruned. Defaults to 60s.

## Instrumenting with Telemetry

The `Oban.Plugins.Pruner` plugin adds the following metadata to the `[:oban, :plugin, :stop]` event:

* `:pruned_jobs` - the jobs that were deleted from the database

_Note: jobs only include `id`, `queue`, `state` fields._