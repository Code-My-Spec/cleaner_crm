# Oban.Migration

Migrations create and modify the database tables Oban needs to function.

## Usage

To use migrations in your application you'll need to generate an `Ecto.Migration` that wraps
calls to `Oban.Migration`:

```bash
mix ecto.gen.migration add_oban
```

Open the generated migration in your editor and call the `up` and `down` functions on
`Oban.Migration`:

```elixir
defmodule MyApp.Repo.Migrations.AddOban do
  use Ecto.Migration

  def up, do: Oban.Migrations.up()

  def down, do: Oban.Migrations.down()
end
```

This will run all of Oban's versioned migrations for your database.

Now, run the migration to create the table:

```bash
mix ecto.migrate
```

Migrations between versions are idempotent. As new versions are released, you may need to run
additional migrations. To do this, generate a new migration:

```bash
mix ecto.gen.migration upgrade_oban_to_v13
```

Open the generated migration in your editor and call the `up` and `down` functions on
`Oban.Migration`, passing a version number:

```elixir
defmodule MyApp.Repo.Migrations.UpgradeObanToV13 do
  use Ecto.Migration

  def up, do: Oban.Migrations.up(version: 13)

  def down, do: Oban.Migrations.down(version: 13)
end
```

## Isolation with Prefixes

Oban supports namespacing through PostgreSQL schemas, also called "prefixes" in Ecto. With
prefixes your jobs table can reside outside of your primary schema (usually public) and you can
have multiple separate job tables.

To use a prefix you first have to specify it within your migration:

```elixir
defmodule MyApp.Repo.Migrations.AddPrefixedObanJobsTable do
  use Ecto.Migration

  def up, do: Oban.Migrations.up(prefix: "private")

  def down, do: Oban.Migrations.down(prefix: "private")
end
```

The migration will create the "private" schema and all tables, functions, and triggers within
that schema. With the database migrated you'll then specify the prefix in your configuration:

```elixir
config :my_app, Oban,
  prefix: "private",
  ...
```

In some cases, for example if your "private" schema already exists and your database user in
production doesn't have permissions to create a new schema, trying to create the schema from the
migration will result in an error. In such situations, it may be useful to inhibit the creation
of the "private" schema:

```elixir
defmodule MyApp.Repo.Migrations.AddPrefixedObanJobsTable do
  use Ecto.Migration

  def up, do: Oban.Migrations.up(prefix: "private", create_schema: false)

  def down, do: Oban.Migrations.down(prefix: "private")
end
```

## Migrating Without Ecto

If your application uses something other than Ecto for migrations, be it an external system or
another ORM, it may be helpful to create plain SQL migrations for Oban database schema changes.

The simplest mechanism for obtaining the SQL changes is to create the migration locally and run
`mix ecto.migrate --log-migrations-sql`. That will log all of the generated SQL, which you can
then paste into your migration system of choice.

Alternatively, if you'd like a more automated approach, try using the [oban_migrations_sql][sql]
project to generate `up` and `down` SQL migrations for you.

[sql]: https://github.com/btwb/oban_migrations_sql

## up/1

Run the `up` changes for all migrations between the initial version and the current version.

## Example

Run all migrations up to the current version:

    Oban.Migration.up()

Run migrations up to a specified version:

    Oban.Migration.up(version: 2)

Run migrations in an alternate prefix:

    Oban.Migration.up(prefix: "payments")

Run migrations in an alternate prefix but don't try to create the schema:

    Oban.Migration.up(prefix: "payments", create_schema: false)

Disable `UNLOGGED` tables for databases that don't support it (e.g. Yugabyte)

    Oban.Migration.up(unlogged: false)

## current_version/1

Get the current migration version.

## Example

    Oban.Migration.current_version()

## down/1

Run the `down` changes for all migrations between the current version and the initial version.

## Example

Run all migrations from current version down to the first:

    Oban.Migration.down()

Run migrations down to and including a specified version:

    Oban.Migration.down(version: 5)

Run migrations in an alternate prefix:

    Oban.Migration.down(prefix: "payments")

## migrated_version/1

Check the latest version the database is migrated to.

## Example

    Oban.Migration.migrated_version()