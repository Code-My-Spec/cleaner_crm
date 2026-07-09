# Phoenix.Ecto.CheckRepoStatus

A plug that does some checks on your application repos.

Checks if the storage is up (database is created) or if there are any pending migrations.
Both checks can raise an error if the conditions are not met.

## Plug options

  * `:otp_app` - name of the application which the repos are fetched from
  * `:migration_paths` - a function that accepts a repo and returns a migration directory, or a list of migration directories, that is used to check for pending migrations
  * `:migration_lock` - the locking strategy used by the Ecto Adapter when checking for pending migrations. Defaults to `false`. Set to `true` to enable migration locks.
  * `:prefix` - the prefix used to check for pending migrations.
  * `:skip_table_creation` - Ecto will not try to create the `schema_migrations` table automatically.  This is useful if you are connecting as a DB user without create permissions