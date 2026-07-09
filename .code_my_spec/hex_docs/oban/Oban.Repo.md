# Oban.Repo

Wrappers around `Ecto.Repo` and `Ecto.Adapters.SQL` callbacks.

Each function resolves the correct repo instance and sets options such as `prefix` and `log`
according to `Oban.Config`.

> #### Meant for Extending Oban {: .warning}
>
> These functions should only be used when working with a repo inside engines, plugins, or other
> extensions for Oban. Favor using your application's repo directly when querying `Oban.Job`
> from your workers.

## Examples

The first argument for every function must be an `Oban.Config` struct. Many functions pass
configuration around as a `conf` key, and it can always be fetched with `Oban.config/1`. This
demonstrates fetching the default instance config and querying all jobs:

    Oban
    |> Oban.config()
    |> Oban.Repo.all(Oban.Job)

## Retries

`transaction/3` is wrapped in a bounded retry loop that tolerates transient failures without
surfacing them to callers:

* `DBConnection.ConnectionError`, `Postgrex.Error`, and `MyXQL.Error` raised from inside a
  transaction are retried with backoff. Expected conflicts like serialization failures,
  deadlocks, and lock-not-available use a shorter delay and higher retry count than unexpected
  errors.

* `UndefinedFunctionError` raised by the configured repo module is retried on the same loop.
  This absorbs the window during which the repo module is unavailable, e.g. mid-recompile in a
  slow dev environment, so periodic plugins and stagers don't crash on a compile blip.
  Non-transaction operations do not retry; wrap them in `transaction/3` if you need the
  protection.

Defaults for both loops are set at compile time and keyed on `Oban.Repo`:

    config :oban, Oban.Repo,
      retry_opts: [
        delay: 500,
        retry: 5,
        expected_delay: 10,
        expected_retry: 20,
        on_exhausted: :raise
      ]

Changes require recompiling `:oban`. See `transaction/3` for the meaning of each option and for
per-call overrides.

## default_options/1

The default values extracted from `Oban.Config` for use in all queries with options.

## query/4

Wraps `Ecto.Adapters.SQL.Repo.query/4` with an added `Oban.Config` argument.

## query!/4

Wraps `Ecto.Adapters.SQL.Repo.query!/4` with an added `Oban.Config` argument.

## to_sql/3

Wraps `Ecto.Adapters.SQL.Repo.to_sql/2` with an added `Oban.Config` argument.

## transaction/3

Wraps `c:Ecto.Repo.transaction/2` with an additional `Oban.Config` argument and automatic
retries with backoff.

Unexpected errors such as `DBConnection.ConnectionError`, `Postgrex.Error`, or `MyXQL.Error`
will retry with a delay scaled by attempt number. Expected conflicts (serialization failures,
deadlocks, and lock-not-available) retry with a shorter delay and higher attempt budget, since
they typically resolve quickly once contention clears.

## Options

In addition to the standard `c:Ecto.Repo.transaction/2` options:

* `:delay` — milliseconds to sleep between unexpected-error retries, scaled by attempt and
  jittered. Defaults to `500`.
* `:retry` — maximum attempts for unexpected errors. Defaults to `5`. Pass `0` or `false` to
  disable retries entirely, including for expected conflicts.
* `:expected_delay` — milliseconds to sleep between expected-conflict retries, jittered.
  Defaults to `10`.
* `:expected_retry` — maximum attempts for expected conflicts. Defaults to `20`.
* `:on_exhausted` — what to do after the retry budget is spent. `:raise` (the default) reraises
  the underlying error, matching the original behavior. `:log` writes a `Logger.error` and
  returns `{:error, exception}`, allowing supervised periodic callers to keep running through a
  database outage instead of crashing and restarting.

Defaults are drawn from the compile-time `:retry_opts` configuration documented on the module.
Any option passed here overrides the compile-time default for this call.

> #### Nested Transactions {: .warning}
>
> When calling `transaction/3` inside an existing transaction, e.g. invoking > `Oban.insert/2`
> from within your application's own `Repo.transaction/2` block, pass `retry: false` to disable
> retries. A retry after a deadlock or serialization failure inside a savepoint will mask the
> real error from the outer transaction and leave you debugging a phantom timeout instead of
> the underlying conflict.

## with_dynamic_repo/2

Executes a function with a dynamic repo using the provided configuration.

This function allows executing queries with a dynamically chosen repo, which may be determined
through either a function or a module/function/args tuple. When used within a transaction, the
dynamic repo is not switched from the current repo.

## Examples

    config = Oban.config(Oban)

    Oban.Repo.with_dynamic_repo(config, fn repo ->
      repo.all(Oban.Job)
    end)