# Ecto.Migrator

Lower level API for managing migrations.

EctoSQL provides three mix tasks for running and managing migrations:

  * `mix ecto.migrate` - migrates a repository
  * `mix ecto.rollback` - rolls back a particular migration
  * `mix ecto.migrations` - shows all migrations and their status

Those tasks are built on top of the functions in this module.
While the tasks above cover most use cases, it may be necessary
from time to time to jump into the lower level API. For example,
if you are assembling an Elixir release, Mix is not available,
so this module provides a nice complement to still migrate your
system.

To learn more about migrations in general, see `Ecto.Migration`.

## Example: Running an individual migration

Imagine you have this migration:

    defmodule MyApp.MigrationExample do
      use Ecto.Migration

      def up do
        execute "CREATE TABLE users(id serial PRIMARY_KEY, username text)"
      end

      def down do
        execute "DROP TABLE users"
      end
    end

You can execute it manually with:

    Ecto.Migrator.up(Repo, 20080906120000, MyApp.MigrationExample)

## Example: Running migrations in a release

Elixir v1.9 introduces `mix release`, which generates a self-contained
directory that consists of your application code, all of its dependencies,
plus the whole Erlang Virtual Machine (VM) and runtime.

When a release is assembled, Mix is no longer available inside a release
and therefore none of the Mix tasks. Users may still need a mechanism to
migrate their databases. This can be achieved with using the `Ecto.Migrator`
module:

    defmodule MyApp.Release do
      @app :my_app

      def migrate do
        for repo <- repos() do
          {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
        end
      end

      def rollback(repo, version) do
        {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
      end

      defp repos do
        Application.load(@app)
        Application.fetch_env!(@app, :ecto_repos)
      end
    end

The example above uses `with_repo/3` to make sure the repository is
started and then runs all migrations up or a given migration down.
Note you will have to replace `MyApp` and `:my_app` on the first two
lines by your actual application name. Once the file above is added
to your application, you can assemble a new release and invoke the
commands above in the release root like this:

    $ bin/my_app eval "MyApp.Release.migrate"
    $ bin/my_app eval "MyApp.Release.rollback(MyApp.Repo, 20190417140000)"

## Example: Running migrations on application startup

Add the following to the top of your application children spec:

    {Ecto.Migrator,
     repos: Application.fetch_env!(:my_app, :ecto_repos),
     skip: System.get_env("SKIP_MIGRATIONS") == "true"}

To skip migrations you can also pass `skip: true` or as in the example
set the environment variable `SKIP_MIGRATIONS` to a truthy value.

And all other options described in `up/4` are allowed,
for example if you want to log the SQL commands,
and run migrations in a prefix:

    {Ecto.Migrator,
     repos: Application.fetch_env!(:my_app, :ecto_repos),
     log_migrator_sql: true,
     prefix: "my_app"}

To roll back you'd do it normally:

    $ mix ecto.rollback

## with_repo/3

Ensures the repo is started to perform migration operations.

All of the application required to run the repo will be started
before hand with chosen mode. If the repo has not yet been started,
it is manually started, with a `:pool_size` of 2, before the given
function is executed, and the repo is then terminated. If the repo
was already started, then the function is directly executed, without
terminating the repo afterwards.

Although this function was designed to start repositories for running
migrations, it can be used by any code, Mix task, or release tooling
that needs to briefly start a repository to perform a certain operation
and then terminate.

The repo may also configure a `:start_apps_before_migration` option
which is a list of applications to be started before the migration
runs.

It returns `{:ok, fun_return, apps}`, with all apps that have been
started, or `{:error, term}`.

## Options

  * `:pool_size` - The pool size to start the repo for migrations.
    Defaults to 2.
  * `:mode` - The mode to start all applications.
    Defaults to `:permanent`.

## Examples

    {:ok, _, _} =
      Ecto.Migrator.with_repo(repo, fn repo ->
        Ecto.Migrator.run(repo, :up, all: true)
      end)

## migrations_path/2

Gets the migrations path from a repository.

This function accepts an optional second parameter to customize the
migrations directory. This can be used to specify a custom migrations
path.

## migrated_versions/2

Gets all migrated versions.

This function ensures the migration table exists
if no table has been defined yet.

## Options

  * `:prefix` - the prefix to run the migrations on
  * `:dynamic_repo` - the name of the Repo supervisor process.
    See `c:Ecto.Repo.put_dynamic_repo/1`.
  * `:skip_table_creation` - skips any attempt to create the migration table
    Useful for situations where user needs to check migrations but has
    insufficient permissions to create the table.  Note that migrations
    commands may fail if this is set to true. Defaults to `false`.  Accepts a
    boolean.

## up/4

Runs an up migration on the given repository.

## Options

  * `:log` - the level to use for logging of migration instructions.
    Defaults to `:info`. Can be any of `Logger.level/0` values or a boolean.
    If `false`, it also avoids logging messages from the database.
  * `:log_migrations_sql` - the level to use for logging of SQL commands
    generated by migrations. Can be any of the `Logger.level/0` values
    or a boolean. If `false`, logging is disabled. If `true`, uses the configured
    Repo logger level. Defaults to `false`
  * `:log_migrator_sql` - the level to use for logging of SQL commands emitted
    by the migrator, such as transactions, locks, etc. Can be any of the `Logger.level/0`
    values or a boolean. If `false`, logging is disabled. If `true`, uses the configured
    Repo logger level. Defaults to `false`
  * `:prefix` - the prefix to run the migrations on
  * `:dynamic_repo` - the name of the Repo supervisor process.
    See `c:Ecto.Repo.put_dynamic_repo/1`.
  * `:strict_version_order` - abort when applying a migration with old timestamp
    (otherwise it emits a warning)

## down/4

Runs a down migration on the given repository.

## Options

  * `:log` - the level to use for logging of migration commands. Defaults to `:info`.
    Can be any of `Logger.level/0` values or a boolean.
  * `:log_migrations_sql` - the level to use for logging of SQL commands
    generated by migrations. Can be any of the `Logger.level/0` values
    or a boolean. If `false`, logging is disabled. If `true`, uses the configured
    Repo logger level. Defaults to `false`
  * `:log_migrator_sql` - the level to use for logging of SQL commands emitted
    by the migrator, such as transactions, locks, etc. Can be any of the `Logger.level/0`
    values or a boolean. If `false`, logging is disabled. If `true`, uses the configured
    Repo logger level. Defaults to `false`
  * `:prefix` - the prefix to run the migrations on
  * `:dynamic_repo` - the name of the Repo supervisor process.
    See `c:Ecto.Repo.put_dynamic_repo/1`.

## run/3

Runs migrations for the given repository.

Equivalent to:

    Ecto.Migrator.run(repo, [Ecto.Migrator.migrations_path(repo)], direction, opts)

See `run/4` for more information.

## migrations/1

Returns an array of tuples as the migration status of the given repo,
without actually running any migrations.

Equivalent to:

    Ecto.Migrator.migrations(repo, [Ecto.Migrator.migrations_path(repo)])

## migrations/3

Returns an array of tuples as the migration status of the given repo,
without actually running any migrations.

## start_link/1

Runs migrations as part of your supervision tree.

## Options

  * `:repos` - Required option to tell the migrator which Repo's to
    migrate. Example: `repos: [MyApp.Repo]`

  * `:skip` - Option to skip migrations. Defaults to `false`.

Plus all other options described in `up/4`.

See "Example: Running migrations on application startup" for more info.