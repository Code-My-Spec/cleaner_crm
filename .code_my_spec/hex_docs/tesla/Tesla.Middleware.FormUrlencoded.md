# Tesla.Middleware.FormUrlencoded

Send request body as `application/x-www-form-urlencoded`.

Performs encoding of `body` from a `Map` such as `%{"foo" => "bar"}` into
URL-encoded data.

Performs decoding of the response into a map when urlencoded and content-type
is `application/x-www-form-urlencoded`, so `"foo=bar"` becomes
`%{"foo" => "bar"}`.

## Examples

```elixir
defmodule Myclient do
  def client do
    Tesla.client([
      {Tesla.Middleware.FormUrlencoded,
        encode: &Plug.Conn.Query.encode/1,
        decode: &Plug.Conn.Query.decode/1}
    ])
  end
end

client = Myclient.client()
Tesla.post(client, "/url", %{key: :value})
```

## Options

- `:decode` - decoding function, defaults to `URI.decode_query/1`
- `:encode` - controls how the body is encoded. Accepts:
  - an arity-1 function that receives the body and returns a binary
    (e.g. `&Plug.Conn.Query.encode/1` or any custom encoder)
  - `:brackets` — recursive bracket-notation encoder for nested maps
    and lists (see `encode: :brackets` below)
  - `{:brackets, opts}` — same encoder with sub-options. Currently
    supports `boolean_as: :string | :integer` (see `encode: :brackets`
    below).
  - Defaults to `URI.encode_query/1` when omitted.

## Nested Maps

Natively, nested maps are not supported in the body, so
`%{"foo" => %{"bar" => "baz"}}` won't be encoded and raise an error.
Support for this specific case is obtained either by setting
`encode: :brackets` (see `encode: :brackets` below) or by
configuring the middleware to encode (and decode) with
`Plug.Conn.Query`:

```elixir
defmodule Myclient do
  def client do
    Tesla.client([
      {Tesla.Middleware.FormUrlencoded,
        encode: &Plug.Conn.Query.encode/1,
        decode: &Plug.Conn.Query.decode/1}
    ])
  end
end

client = Myclient.client()
Tesla.post(client, "/url", %{key: %{nested: "value"}})
```

## `encode: :brackets`

Recursive indexed-bracket form encoder for nested maps and lists.

The output shape — `key[0]=a&key[1]=b` for arrays, `a[b][c]=1` for
nested objects — is the de-facto convention used by Stripe, Rack,
PHP's `http_build_query`, qs (with `arrayFormat: 'indices'`), and
ASP.NET model binding. It is not defined by any RFC. The OpenAPI 3.0.4
and 3.1.1 specs cover the object case under [`deepObject`
style](https://spec.openapis.org/oas/v3.1.0#style-values) but
explicitly state that *"the representation of array or object
properties is not defined"*, which this encoder fills in with the
conventions above.

Percent-encoding of keys and values follows
`application/x-www-form-urlencoded` (WHATWG URL Standard / PHP's
default `PHP_QUERY_RFC1738`): spaces become `+`, reserved characters
become `%XX`.

```elixir
client = Tesla.client([{Tesla.Middleware.FormUrlencoded, encode: :brackets}])

Tesla.post(client, "/url", %{
  expand: ["objects"],
  objects: %{customers: ["cus_123", "cus_456"]}
})
# body: "expand[0]=objects&objects[customers][0]=cus_123&objects[customers][1]=cus_456"
```

### Booleans (`boolean_as`)

Booleans default to the lowercase strings `true` / `false`, which is
the wire format required by Stripe's V2 API (see [stripe-python PR
#1499](https://github.com/stripe/stripe-python/pull/1499)) and used by
every official Stripe SDK. PHP's `http_build_query` would instead emit
`1` for `true` and `0` for `false`; opt in to that behavior with
`boolean_as: :integer`:

```elixir
# default: Stripe-compatible
client = Tesla.client([{Tesla.Middleware.FormUrlencoded, encode: :brackets}])
Tesla.post(client, "/url", %{active: true})
# body: "active=true"

# opt in to PHP http_build_query parity
client =
  Tesla.client([{Tesla.Middleware.FormUrlencoded, encode: {:brackets, boolean_as: :integer}}])
Tesla.post(client, "/url", %{active: true})
# body: "active=1"
```

With `boolean_as: :integer`, the encoder's output matches PHP
`http_build_query` byte-for-byte (after URL-decoding `%5B`/`%5D` to
literal `[`/`]`) across the verified test corpus. Use `:string`
(default) for Stripe and most modern APIs; use `:integer` only when
targeting a server that specifically requires the PHP-native form.

### `nil` vs empty string

The encoder distinguishes "don't include this field" from "include the
field with an empty value". This matches the three-state semantics
exposed by Stripe's update endpoints (and PHP's `http_build_query`):

| Input value | Wire output | Typical API meaning on update |
| --- | --- | --- |
| `nil` | (nothing emitted) | Field is absent from the request — the server leaves the existing value untouched. |
| `""` (empty string) | `key=` | Field is present with an empty value — the server clears or unsets it. |
| any other value | `key=value` | Field is set to the given value. |

Use `nil` to mean "leave this field alone" and `""` to mean "clear this
field". For example, on `POST /v1/customers/cus_X`:

```elixir
# Leaves customer.metadata.foo untouched (field not in request):
%{metadata: %{plan: "pro"}}
# → metadata[plan]=pro

# Deletes the foo key from customer.metadata (sent with empty value):
%{metadata: %{foo: ""}}
# → metadata[foo]=
```

Inside lists the same rule applies element-by-element: `nil` elements
are dropped while the index of remaining elements is preserved
(`[a, nil, b]` → `[0]=a&[2]=b`, matching PHP `http_build_query`), and
`""` elements are emitted as `key[i]=`.

### Root containers

The root accepts any ordered name/value pair-sequence, which matches
the `application/x-www-form-urlencoded` wire-level data model:

- `Map` — most common; iteration order is undefined.
- Keyword list (`[a: 1, b: 2]`) — preserves the order you give it.
- List of 2-tuples (`[{"tag", "a"}, {"tag", "b"}]`) — preserves order
  *and* allows duplicate keys and non-atom keys
  (`[{"tag", "a"}, {"tag", "b"}]` → `tag=a&tag=b`).

Anything else at the root (`42`, `[1, 2, 3]`, `[{:a, 1}, 2]`, a
struct) raises `ArgumentError`.

### Nested containers

Inside the payload the shape is strict, no inference:

- `Map` is always an object → `parent[key]=value`.
- `List` is always an array → `parent[0]=…&parent[1]=…`.
- A tuple appearing inside a map or list raises — use a map for
  object-shaped nesting.
- Structs raise `ArgumentError` — convert them with
  `Map.from_struct/1` or `to_string/1` first.

### Other behavior worth knowing

- Empty lists and empty maps emit nothing, which means the parent key
  disappears entirely: `%{ids: []}` → `""`, and `%{user: %{tags: []}}`
  → `""`. This matches PHP `http_build_query`. Send `""` to clear a
  field on Stripe-style update endpoints.
- Map keys are not ordered; keyword lists and lists of 2-tuples
  preserve the order you give them.
- Decoding stays flat. `Plug.Conn.Query.decode/1` will parse the
  bracket keys into nested maps, but indexed lists come back as maps
  keyed by string indices (`"0"`, `"1"`, …), not as Elixir lists, so
  the round-trip is not symmetric.

## encode/2

Encode response body as querystring.

It is used by `Tesla.Middleware.EncodeFormUrlencoded`.

## decode/2

Decode response body as querystring.

It is used by `Tesla.Middleware.DecodeFormUrlencoded`.