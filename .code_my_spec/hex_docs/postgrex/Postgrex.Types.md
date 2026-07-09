# Postgrex.Types

Encodes and decodes between PostgreSQL protocol and Elixir values.

## define/3

Defines a type module with custom extensions and options.

`Postgrex.Types.define/3` must be called on its own file, outside of
any module and function, as it only needs to be defined once during
compilation.

Type modules are given to Postgrex on `start_link` via the `:types`
option and are used to control how Postgrex encodes and decodes data
coming from PostgreSQL.

For example, to define a new type module with a custom extension
called `MyExtension` while also changing `Postgrex`'s default
behaviour regarding binary decoding, you may create a new file
called "lib/my_app/postgrex_types.ex" with the following:

    Postgrex.Types.define(MyApp.PostgrexTypes, [MyExtension], [decode_binary: :reference])

The line above will define a new module, called `MyApp.PostgrexTypes`
which can be passed as `:types` when starting Postgrex. The type module
works by rewriting and inlining the extensions' encode and decode
expressions in an optimal fashion for postgrex to encode parameters and
decode multiple rows at a time.

## Extensions

Extensions is a list of `Postgrex.Extension` modules or a 2-tuple
containing the module and a keyword list. The keyword, defaulting
to `[]`, will be passed to the modules `init/1` callback.

Extensions at the front of the list will take priority over later
extensions when the `matching/1` callback returns have conflicting
matches. If an extension is not provided for a type then Postgrex
will fallback to default encoding/decoding methods where possible.
All extensions that ship as part of Postgrex are included out of the
box.

See `Postgrex.Extension` for more information on extensions.

## Options

  * `:null` - The atom to use as a stand in for postgres' `NULL` in
    encoding and decoding. The module attribute `@null` is registered
    with the value so that extension can access the value if desired
    (default: `nil`);

  * `:decode_binary` - Either `:copy` to copy binary values when decoding
    with default extensions that return binaries or `:reference` to use a
    reference counted binary of the binary received from the socket.
    Referencing a potentially larger binary can be more efficient if the binary
    value is going to be garbaged collected soon because a copy is avoided.
    However the larger binary can not be garbage collected until all references
    are garbage collected (default: `:copy`);

  * `:json` - The JSON module to encode and decode JSON binaries, calls
    `module.encode_to_iodata!/1` to encode and `module.decode!/1` to decode.
    If `nil` then no default JSON handling
    (default: `Application.get_env(:postgrex, :json_library, Jason)`);

  * `:bin_opt_info` - Either `true` to enable binary optimisation information,
    or `false` to disable, for more information see `Kernel.SpecialForms.<<>>/1`
    in Elixir (default: `false`);

  * `:debug_defaults` - Generate debug information when building default
    extensions so they point to the proper source. Enabling such option
    will increase the time to compile the type module (default: `false`);

  * `:moduledoc` - The moduledoc to be used for the generated module.

  * `:allow_infinite_timestamps` - A boolean controlling whether or not
    the built-in extensions `timestamp` and `timestamptz` will allow
    infinite values (`:inf`/`:"-inf"`) to be decoded. Defaults to `false`.

  * `:allow_infinite_intervals` - A boolean controlling whether or not
    the built-in extension `interval` will allow infinite values (`:inf`/`:"-inf"`)
    to be encoded and decoded. Defaults to `false`.

  * `:interval_decode_type` - The struct that intervals will be decoded
    into. Either `Postgrex.Interval` or `Duration` (Elixir 1.17.0+ only).
    Defaults to `Postgrex.Interval`.