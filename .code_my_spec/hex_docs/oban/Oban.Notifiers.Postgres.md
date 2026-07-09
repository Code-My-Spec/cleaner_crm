# Oban.Notifiers.Postgres

A Postgres LISTEN/NOTIFY based Notifier.

> #### Connection Pooling {: .info}
>
> Postgres PubSub is fine for most applications, but it doesn't work with connection poolers
> like [PgBouncer][pgb] when configured in _transaction_ or _statement_ mode, which is
> standard. Notifications are required for some core Oban functionality, and you should
> consider using an alternative notifier such as `Oban.Notifiers.PG`.

## Usage

Specify the `Postgres` notifier in your Oban configuration:

    config :my_app, Oban,
      notifier: Oban.Notifiers.Postgres,
      ...

### Transactions and Testing

The notifications system is built on PostgreSQL's `LISTEN/NOTIFY` functionality. Notifications
are only delivered **after a transaction completes** and are de-duplicated before publishing.
This means that notifications sent during a transaction will not be sent if the transaction is
rolled back, providing consistency; this is the only notifer which provides that guarantee.
However, it is not as scalable as other notifiers because each notification requires a
separate query and notifications can't exceed 8kb.

Typically, applications run Ecto in sandbox mode while testing, but sandbox mode wraps each test
in a separate transaction that's rolled back after the test completes. That means the
transaction is never committed, which prevents delivering any notifications.

To test using notifications you must run Ecto without sandbox mode enabled, or use
`Oban.Notifiers.PG` instead.

[pgb]: https://www.pgbouncer.org/