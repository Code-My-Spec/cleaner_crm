# Tesla.OpenAPI.QueryString

A whole URL query string with explicit serialization.

`Tesla.OpenAPI.QueryString` is a value object for requests where the entire
query string is serialized as one value. It is useful for OpenAPI 3.2
[`in: "querystring"` parameters][oas-parameter-locations], where the query
string is content-based and does not behave like a normal named query
parameter.

Pass a query string value directly as the request `:query`:

    alias Tesla.OpenAPI.QueryString

    Tesla.get(client, "/search",
      query: QueryString.form!(foo: "a + b", bar: true)
    )

The encoded query string is resolved before the adapter sends the request.

## Constructors

  * `raw!/2` - accepts an already-serialized query string, without the leading
    `?`.
  * `form!/1` - serializes structured params as
    `application/x-www-form-urlencoded` using Tesla's default query encoder.

[oas-parameter-locations]: https://spec.openapis.org/oas/latest.html#parameter-locations