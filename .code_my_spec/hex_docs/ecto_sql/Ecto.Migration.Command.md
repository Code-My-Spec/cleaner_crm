# Ecto.Migration.Command

Used internally by adapters.

This represents the up and down legs of a reversible raw command
that is usually defined with `Ecto.Migration.execute/1`.

To define a reversible command in a migration, see `Ecto.Migration.execute/2`.