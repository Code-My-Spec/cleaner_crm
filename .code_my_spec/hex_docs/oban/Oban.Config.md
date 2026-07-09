# Oban.Config

The Config struct validates and encapsulates Oban instance state.

Typically, you won't use the Config module directly. Oban automatically creates a Config struct
on initialization and passes it through to all supervised children with the `:conf` key.

To fetch a running Oban supervisor's config, see `Oban.config/1`.

## new/1

Generate a Config struct after normalizing and verifying Oban options.

See `Oban.start_link/1` for a comprehensive description of available options.

## Example

Generate a minimal config with only a `:repo`:

    Oban.Config.new(repo: Oban.Test.Repo)

## validate/1

Verify configuration options.

This helper is used by `new/1`, and therefore by `Oban.start_link/1`, to verify configuration
options when an Oban supervisor starts. It is provided publicly to aid in configuration testing,
as `test` config may differ from `prod` config.

# Example

Validating top level options:

    iex> Oban.Config.validate(name: Oban)
    :ok

    iex> Oban.Config.validate(name: Oban, log: false)
    :ok

    iex> Oban.Config.validate(node: {:not, :binary})
    {:error, "expected :node to be a binary, got: {:not, :binary}"}

    iex> Oban.Config.validate(plugins: true)
    {:error, "invalid value for :plugins, expected :plugins to be a list, got: true"}

Validating plugin options:

    iex> Oban.Config.validate(plugins: [{Oban.Plugins.Pruner, max_age: 60}])
    :ok

    iex> Oban.Config.validate(plugins: [{Oban.Plugins.Pruner, max_age: 0}])
    {:error, "invalid value for :plugins, expected :max_age to be a positive integer, got: 0"}