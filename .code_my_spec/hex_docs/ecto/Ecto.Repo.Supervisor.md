# Ecto.Repo.Supervisor



## start_link/4

Starts the repo supervisor.

## init_config/4

Retrieves the runtime configuration.

## compile_config/2

Retrieves the compile time configuration.

## parse_url/1

Parses an Ecto URL allowed in configuration.

The format must be:

    "ecto://username:password@hostname:port/database?ssl=true&timeout=1000"