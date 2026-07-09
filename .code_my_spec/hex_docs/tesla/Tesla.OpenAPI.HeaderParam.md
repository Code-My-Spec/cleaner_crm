# Tesla.OpenAPI.HeaderParam

A header parameter with explicit serialization settings.

`Tesla.OpenAPI.HeaderParam` is a value object for header parameters whose
serialization needs to be controlled explicitly. Its serialization options
follow the OpenAPI header parameter style semantics.

Define header parameters once and apply them to request values with
`Tesla.OpenAPI.HeaderParams`:

    alias Tesla.OpenAPI.{HeaderParam, HeaderParams}

    header_params =
      HeaderParams.new!([
        HeaderParam.new!("X-Token")
      ])

    HeaderParams.to_headers(header_params, %{"X-Token" => [12345678, 90099]})

[oas-style]: https://spec.openapis.org/oas/latest.html#style-values

## Encoding

`Tesla.OpenAPI.HeaderParams.to_headers/2` serializes values using the
[OpenAPI header parameter rules][oas-style] for the `simple` style. Header
values are passed through unchanged after converting each part with
`to_string/1`; URI percent-encoding is not applied.

## Object Value Ordering

Object values may be passed as maps, structs, or keyword lists. Keyword lists
preserve insertion order; map iteration order is intrinsic and not guaranteed
across Elixir versions. Pass an ordered keyword list when the exact
serialized order matters.

## new!/2

Creates a header parameter definition.

Options use Elixir atoms for hand-written Tesla code:

  * `:style` - must be `:simple`. Defaults to `:simple`.
  * `:explode` - boolean. Defaults to `false`.