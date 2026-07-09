# Phoenix

This is the documentation for the Phoenix project.

To get started, see our [overview guides](overview.md).

## json_library/0

Returns the configured JSON encoding library for Phoenix.

To customize the JSON library, including the following
in your `config/config.exs`:

    config :phoenix, :json_library, AlternativeJsonLibrary

The configured module is required to provide three functions:

- **`decode!/1`** — decodes a JSON binary, raising on invalid input
- **`encode!/1`** — encodes a term to a JSON binary, raising on encoding errors
- **`encode_to_iodata!/1`** — encodes a term to JSON as iodata, raising on
encoding errors.

These correspond to the single-argument, raising variants of
the functions provided by Elixir's built-in `JSON` module. A conforming
`:json_library` module does not need to implement any other functions
`JSON` has, that are not defined above.

## plug_init_mode/0

Returns the `:plug_init_mode` that controls when plugs are
initialized.

We recommend to set it to `:runtime` in development for
compilation time improvements. It must be `:compile` in
production (the default).

This option is passed as the `:init_mode` to `Plug.Builder.compile/3`.