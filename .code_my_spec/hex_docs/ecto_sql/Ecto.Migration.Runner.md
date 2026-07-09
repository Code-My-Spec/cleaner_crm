# Ecto.Migration.Runner



## run/8

Runs the given migration.

## metadata/2

Stores the runner metadata.

## start_link/1

Starts the runner for the specified repo.

## stop/0

Stops the runner.

## repo_config/2

Accesses the given repository configuration.

## migrator_direction/0

Returns the migrator command (up or down).

  * forward + up: up
  * forward + down: down
  * forward + change: up
  * backward + change: down

## repo/0

Gets the repo for this migration

## prefix/0

Gets the prefix for this migration

## flush/0

Executes queue migration commands.

Reverses the order commands are executed when doing a rollback
on a change/0 function and resets commands queue.

## execute/1

Queues command tuples or strings for execution.

Ecto.MigrationError will be raised when the server
is in `:backward` direction and `command` is irreversible.

## start_command/1

Starts a command.

## end_command/0

Queues and clears current command. Must call `start_command/1` first.

## subcommand/1

Adds a subcommand to the current command. Must call `start_command/1` first.