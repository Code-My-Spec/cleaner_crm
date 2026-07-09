# Oban.Plugins.Cron

Periodically enqueue jobs through [cron](https://en.wikipedia.org/wiki/Cron)-based scheduling.

This plugin registers workers a cron-like schedule and enqueues jobs automatically. To know
more about periodic jobs in Oban, see the [*Periodic Jobs* guide][perjob].

> #### 🌟 DynamicCron {: .info}
>
> This plugin only loads the crontab statically, at boot time. To configure cron scheduling at
> runtime, globally, across an entire cluster with scheduling guarantees and timezone overrides,
> see the [`DynamicCron` plugin in Oban Pro](https://oban.pro/docs/pro/Oban.Pro.Plugins.DynamicCron.html).

## Usage

Periodic jobs are declared as a list of `{cron, worker}` or `{cron, worker, options}` tuples:

```elixir
config :my_app, Oban,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"* * * * *", MyApp.MinuteWorker},
       {"0 * * * *", MyApp.HourlyWorker, args: %{custom: "arg"}},
       {"0 0 * * *", MyApp.DailyWorker, max_attempts: 1},
       {"0 12 * * MON", MyApp.MondayWorker, queue: :scheduled, tags: ["mondays"]},
       {"@daily", MyApp.AnotherDailyWorker}
     ]}
  ]
```

### Identifying Cron Jobs

Jobs inserted by the cron plugin are marked with a `cron` flag and the _original_ expression is
stored as `cron_expr` in the job's `meta` field. For example, the meta for a `@daily` cron job
would look like this:

```elixir
%Oban.Job{meta: %{"cron" => true, "cron_expr" => "@daily", "cron_tz" => "Etc/UTC"}}
```

## Options

You can pass the following options to this plugin:

* `:crontab` — a list of cron expressions that enqueue jobs on a periodic basis. See [*Periodic
  Jobs* guide][perjob] for syntax and details.

* `:timezone` — which timezone to use when scheduling cron jobs. To use a timezone other than
  the default of `Etc/UTC` you *must* have a timezone database like [tz][tz] installed and
  configured.

## Instrumenting with Telemetry

The `Oban.Plugins.Cron` plugin adds the following metadata to the `[:oban, :plugin, :stop]`
event (see `Oban.Telemetry`):

* `:jobs` — a list of jobs that were inserted into the database

[tz]: https://hexdocs.pm/tz
[perjob]: periodic_jobs.html

## entry_name/1

Parse a crontab expression into a cron struct.

This is provided as a convenience for validating and testing cron expressions. As such, the cron
struct itself is opaque and the internals may change at any time.

The parser can handle common expressions that use minutes, hours, days, months and weekdays,
along with ranges and steps. It also supports common extensions, also called nicknames.

Returns `{:error, %ArgumentError{}}` with a detailed error if the expression cannot be parsed.

## Nicknames

The following special nicknames are supported in addition to standard cron expressions:

  * `@yearly`—Run once a year, "0 0 1 1 *"
  * `@annually`—Same as `@yearly`
  * `@monthly`—Run once a month, "0 0 1 * *"
  * `@weekly`—Run once a week, "0 0 * * 0"
  * `@daily`—Run once a day, "0 0 * * *"
  * `@midnight`—Same as `@daily`
  * `@hourly`—Run once an hour, "0 * * * *"
  * `@reboot`—Run once at boot

## Examples

    iex> Oban.Plugins.Cron.parse("@hourly")
    {:ok, #Oban.Cron.Expression<...>}

    iex> Oban.Plugins.Cron.parse("0 * * * *")
    {:ok, #Oban.Cron.Expression<...>}

    iex> Oban.Plugins.Cron.parse("60 * * * *")
    {:error, %ArgumentError{message: "expression field 60 is out of range 0..59"}}