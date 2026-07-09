# Oban.Plugins.Reindexer

Periodically rebuild indexes to minimize database bloat.

Over time various Oban indexes may grow without `VACUUM` cleaning them up properly. When this
happens, rebuilding the indexes will release bloat.

The plugin uses `REINDEX` with the `CONCURRENTLY` option to rebuild without taking any locks
that prevent concurrent inserts, updates, or deletes on the table.

## Using the Plugin

By default, the plugin will reindex once a day, at midnight UTC:

    config :my_app, Oban,
      plugins: [Oban.Plugins.Reindexer],
      ...

To run on a different schedule you can provide a cron expression. For example, you could use the
`"@weekly"` shorthand to run once a week on Sunday:

    config :my_app, Oban,
      plugins: [{Oban.Plugins.Reindexer, schedule: "@weekly"}],
      ...

## Options

  * `:indexes` — a list of indexes to reindex on the `oban_jobs` table. Defaults to only the
    `oban_jobs_args_index` and `oban_jobs_meta_index`.

  * `:schedule` — a cron expression that controls when to reindex. Defaults to `"@midnight"`.

  * `:timeout` - time in milliseconds to wait for each query call to finish. Defaults to 15 seconds.

  * `:timezone` — which timezone to use when evaluating the schedule. To use a timezone other than
    the default of "Etc/UTC" you *must* have a timezone database like [tz][tz] installed and
    configured.

[tz]: https://hexdocs.pm/tz