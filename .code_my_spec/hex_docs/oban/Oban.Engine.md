# Oban.Engine

Defines an Engine for job orchestration.

Engines are responsible for all non-plugin database interaction, from inserting through
executing jobs.

Oban ships with three Engine implementations:

1. `Basic` — The default engine for development, production, and manual testing mode.
2. `Inline` — Designed specifically for testing, it executes jobs immediately, in-memory, as
   they are inserted.
3. `Lite` - The engine for running Oban using SQLite3.

> #### 🌟 SmartEngine {: .info}
>
> The Basic engine lacks advanced functionality such as global limits, rate limits, and
> unique bulk insert. For those features and more, see the [`Smart` engine in Oban
> Pro](https://oban.pro/docs/pro/Oban.Pro.Engines.Smart.html).

## init/2

Update a job with the given changes map. The job must not be currently executing.