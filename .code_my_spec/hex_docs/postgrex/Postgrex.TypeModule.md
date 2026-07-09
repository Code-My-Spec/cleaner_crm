# Postgrex.TypeModule



## define/3

Creates a module to aid in type processing.

The resulting module has three main purposes:

  1. Associate the type information from the bootstrap query to extensions
  2. Encode Elixir data types into binaries to send to the Postgres server
  3. Decode binaries sent from the Postgres server into Elixir data types

The first point is handled by creating a `find/2` function that accepts a `%Postgrex.TypeInfo{}`
struct and a format such as `:binary`, `:text`, `:any`. It returns either a 2-tuple for
regular extensions containing the format and the extension name or a 3-tuple for super
extensions containing the format, the extension name and the sub-oids. Some important points:

  - The type infos are associated to extensions using the `matching/1` callback
  - The sub-oids for super extensions are created using the `oids/2` callback

The second point is handled by creating encoding functions for each extension. These functions
are created by iterating over each extension, taking the pattern returned by the `encode/1`
callback and creating a function that either:

  - Accepts the pattern for regular extensions
  - Accepts the pattern, sub-oids and sub-tupes for super extensions

Each function is given the same name as the extension module and simply returns the body of the
`encode/1` callback. Several helper functions that help encode parameters, lists, tuples and
values are also exposed and can be called either locally or remotely. These helper functions
eventually call the encoding functions specific to each extension.

The third point is handled by creating decoding functions for each extension. These functions
are created by iterating over each extension, taking the pattern returned by the `decode/1`
callback and creating a function that either:

  - Accepts the pattern for regular extensions
  - Accepts the pattern, sub-oids and sub-tupes for super extensions

Each function also accepts several variables that help accumulate the results and a special
variable `mod` that allows the extensions to access the type modifier of the column. This
allows them, for example, to return the correct precision for timestamps.

Each function is given the same name as the extension module and adds the body of the `decode/1`
callback to the accumulated results. Helper functions that help decode lists and tuples are also
exposed. These helper functions eventually call the decoding functions specific to each extension.