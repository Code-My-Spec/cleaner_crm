# Tesla.OpenAPI.QueryParam

A query parameter definition with explicit serialization settings.

`Tesla.OpenAPI.QueryParam` is a value object for query parameter metadata
whose serialization needs to be controlled explicitly. Its serialization
options follow the OpenAPI query parameter style semantics.

In `Tesla.Middleware.Query` `:modern` mode, define query parameters once and
pass them through `t:Tesla.Env.private/0` with `Tesla.OpenAPI.QueryParams`:

    alias Tesla.OpenAPI.{QueryParam, QueryParams}

    query_params = QueryParams.new!([QueryParam.new!("id")])
    private = QueryParams.put_private(query_params)

    Tesla.get(client, "/items",
      query: %{"id" => 42},
      private: private
    )

Pass options when a query value needs non-default serialization:

    alias Tesla.OpenAPI.QueryParam

    Tesla.OpenAPI.QueryParams.new!([
      QueryParam.new!("ids", style: :pipe_delimited)
    ])

[oas-style]: https://spec.openapis.org/oas/latest.html#style-values

## Encoding

`Tesla.Middleware.Query` serializes values using the [OpenAPI query
parameter rules][oas-style] for the `form`, `space_delimited`,
`pipe_delimited`, and `deep_object` styles. Serialized names and values are
percent-encoded against the RFC 3986 unreserved set (`A-Z`, `a-z`, `0-9`,
`-`, `_`, `.`, `~`); spaces become `%20` (not `+`).

With `allow_reserved: true`, reserved characters and already-encoded percent
triples in values are preserved. Names are always encoded with the default
query-name encoding.

## Object Value Ordering

Object values may be passed as maps, structs, or keyword lists. Keyword lists
preserve insertion order; map iteration order is intrinsic and not guaranteed
across Elixir versions. Pass an ordered keyword list when the exact
serialized order matters.

## OpenAPI additionalProperties

OpenAPI `additionalProperties` belongs to the schema of an object-valued
parameter. Model that parameter with `Tesla.OpenAPI.QueryParam` and pass the dynamic
properties as the request value:

    query_params = Tesla.OpenAPI.QueryParams.new!([Tesla.OpenAPI.QueryParam.new!("filter")])
    query = %{"filter" => [status: "open", owner: "yordis"]}

In `:form` style with `explode: true`, this serializes to
`?status=open&owner=yordis`.

## Missing And Empty Values

Skip a query parameter by leaving it out of `env.query`. A present `nil`
value represents the OpenAPI "undefined" value and only has a defined
serialization for `:form`.

## new!/2

Creates a query parameter definition.

Options use Elixir atoms for hand-written Tesla code:

  * `:style` - one of `:form`, `:space_delimited`, `:pipe_delimited`, or
    `:deep_object`. Defaults to `:form`.
  * `:explode` - boolean. Defaults to `true` when the style is `:form`,
    and `false` for all other styles.
  * `:allow_reserved` - boolean. Defaults to `false`.