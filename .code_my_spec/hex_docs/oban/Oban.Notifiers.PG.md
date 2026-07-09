# Oban.Notifiers.PG

A [PG (Process Groups)][pg] based notifier implementation that runs with Distributed Erlang.
This notifier scales much better than `Oban.Notifiers.Postgres` but lacks its transactional
guarantees.

> #### Distributed Erlang {: .info}
>
> PG requires a functional [Distributed Erlang][de] cluster to broadcast between nodes. If your
> application isn't clustered, then you should consider an alternative notifier such as
> `Oban.Notifiers.Postgres`

## Usage

Specify the `PG` notifier in your Oban configuration:

```elixir
config :my_app, Oban,
  notifier: Oban.Notifiers.PG,
  ...
```

By default, all Oban instances using the same `prefix` option will receive notifications from
each other. You can use the `namespace` option to separate instances that are in the same
cluster _without_ changing the prefix:

```elixir
config :my_app, Oban,
  notifier: {Oban.Notifiers.PG, namespace: :custom_namespace}
  ...
```

The namespace may be any term.

[pg]: https://www.erlang.org/doc/man/pg.html
[de]: https://elixir-lang.org/getting-started/mix-otp/distributed-tasks.html#our-first-distributed-code