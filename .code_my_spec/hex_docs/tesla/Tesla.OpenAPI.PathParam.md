# Tesla.OpenAPI.PathParam

A path parameter definition with explicit serialization settings.

`Tesla.OpenAPI.PathParam` is a value object for path parameter metadata whose
serialization needs to be controlled explicitly. Its serialization options
follow the OpenAPI path parameter style semantics.

In `Tesla.Middleware.PathParams` `:modern` mode, define path parameters once
and pass them through `t:Tesla.Env.private/0` with `Tesla.OpenAPI.PathParams`:

    path_params = Tesla.OpenAPI.PathParams.new!([PathParam.new!("id")])
    private = Tesla.OpenAPI.PathParams.put_private(path_params)

    Tesla.get(client, "/items/{id}",
      opts: [path_params: %{"id" => 42}],
      private: private
    )

Pass options when a value needs non-default path serialization:

    alias Tesla.OpenAPI.PathParam

    Tesla.OpenAPI.PathParams.new!([
      PathParam.new!("coords", style: :matrix, explode: true)
    ])

[oas-style]: https://spec.openapis.org/oas/latest.html#style-values

## Encoding

`Tesla.Middleware.PathParams` serializes values using the
[OpenAPI path parameter rules][oas-style] for the `simple`, `matrix`, and
`label` styles. Serialized values are percent-encoded against the RFC 3986
unreserved set (`A-Z`, `a-z`, `0-9`, `-`, `_`, `.`, `~`); spaces become
`%20` (not `+`).

With `allow_reserved: true`, path-safe reserved characters are preserved, but
characters that would change the URL path shape, such as `/`, `?`, or `#`,
are still percent-encoded.

## Object Value Ordering

Object values may be passed as maps, structs, or keyword lists. Keyword lists
preserve insertion order; map iteration order is intrinsic and not guaranteed
across Elixir versions. Pass an ordered keyword list when the exact
serialized order matters.

## Missing And Empty Values

Path parameters are required per the OpenAPI Specification
([Parameter Object — `required`](https://spec.openapis.org/oas/latest.html#parameter-required)).
When `Tesla.Middleware.PathParams` runs in `:modern` mode and request values
are supplied via `opts[:path_params]`, it raises `ArgumentError` if a defined
placeholder's value is missing or `nil`. Empty arrays and empty objects
serialize according to the OpenAPI "undefined" column for the selected style.

## new!/2

Creates a path parameter definition.

Path parameters are always required per the OpenAPI Specification:
[Parameter Object — `required`](https://spec.openapis.org/oas/latest.html#parameter-required).

Options use Elixir atoms for hand-written Tesla code:

  * `:style` — one of `:simple`, `:matrix`, `:label`. Defaults to `:simple`.
  * `:explode` — boolean. Defaults to `false`.
  * `:allow_reserved` — boolean. Defaults to `false`.