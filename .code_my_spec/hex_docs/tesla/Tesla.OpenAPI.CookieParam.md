# Tesla.OpenAPI.CookieParam

A cookie parameter with explicit serialization settings.

`Tesla.OpenAPI.CookieParam` is a value object for cookie parameters whose
serialization needs to be controlled explicitly. Its serialization options
follow the OpenAPI cookie parameter style semantics.

Define cookie parameters once and apply them to request values with
`Tesla.OpenAPI.CookieParams`:

    alias Tesla.OpenAPI.{CookieParam, CookieParams}

    cookie_params =
      CookieParams.new!([
        CookieParam.new!("session_id"),
        CookieParam.new!("theme")
      ])

    CookieParams.to_headers(cookie_params, %{
      "session_id" => "abc123",
      "theme" => "dark"
    })

[oas-style]: https://spec.openapis.org/oas/latest.html#style-values

## Encoding

`Tesla.OpenAPI.CookieParams.to_headers/2` serializes values using the
[OpenAPI cookie parameter rules][oas-style] for the `form` and `cookie`
styles.

The `cookie` style follows `Cookie` header syntax by separating name-value
pairs with `"; "`. Values are passed through unchanged after converting each
part with `to_string/1`; URI percent-encoding is not applied.

The `form` style follows the OpenAPI compatibility behavior for cookie
parameters and applies URI percent-encoding by default. With
`allow_reserved: true`, reserved characters and already-encoded percent
triples in values are preserved.

## Object Value Ordering

Object values may be passed as maps, structs, or keyword lists. Keyword lists
preserve insertion order; map iteration order is intrinsic and not guaranteed
across Elixir versions. Pass an ordered keyword list when the exact
serialized order matters.

## new!/2

Creates a cookie parameter definition.

Options use Elixir atoms for hand-written Tesla code:

  * `:style` - one of `:form` or `:cookie`. Defaults to `:form`, matching
    the OpenAPI compatibility default for cookie parameters.
  * `:explode` - boolean. Defaults to `true` when the style is `:form`,
    and `false` for all other styles.
  * `:allow_reserved` - boolean. Defaults to `false`.