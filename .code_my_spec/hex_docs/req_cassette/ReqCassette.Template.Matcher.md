# ReqCassette.Template.Matcher

Matches templated requests by comparing their structure (template markers), not values.

During replay, we create a templated version of the incoming request and compare it
to the cassette's templated request. If the structures match (same template markers
in the same positions), we can use the cassette.

## Key Insight

We match on **template structure** (`{{sku.0}}`), not the actual values
(`0234-3455` vs `6785-9443`).

## Examples

    # Recording
    Request: "List SKU 0234-3455 and SKU 0344-4456"
    Templated: "List SKU {{sku.0}} and SKU {{sku.1}}"

    # Replay with different SKUs
    Request: "List SKU 6785-9443 and SKU 3488-3234"
    Templated: "List SKU {{sku.0}} and SKU {{sku.1}}"

    # Match: YES ✅ - Same structure, different values

    # Replay with different structure
    Request: "List SKU 6785-9443 but exclude SKU 3488-3234"
    Templated: "List SKU {{sku.0}} but exclude SKU {{sku.1}}"

    # Match: NO ❌ - Different structure ("and" vs "but exclude")

## What Gets Matched

The matcher compares templated request maps on these fields:
- `"method"` - HTTP method
- `"uri"` - Full URI (with template markers if applicable)
- `"query_string"` - Query string (with template markers)
- `"body"` or `"body_json"` - Body content (with template markers)

Headers are NOT compared (to avoid auth token issues).

## Normalization

Both requests should be normalized before templating to ensure consistent
comparison (see `ReqCassette.Template.Normalizer`).

## match?/3

Checks if two templated requests match.

Compares the structure of templated requests, ignoring actual values and
only looking at template markers and static text.

## Parameters

- `cassette_request` - Templated request from cassette (with markers like `{{sku.0}}`)
- `incoming_request` - Templated version of incoming request

## Returns

- `:match` if structures are identical
- `{:error, diff}` if they don't match, with diff details

## Examples

    iex> cassette_req = %{
    ...>   "method" => "GET",
    ...>   "uri" => "https://api.example.com/sku/{{sku.0}}",
    ...>   "body" => ""
    ...> }
    iex> incoming_req = %{
    ...>   "method" => "GET",
    ...>   "uri" => "https://api.example.com/sku/{{sku.0}}",
    ...>   "body" => ""
    ...> }
    iex> match?(cassette_req, incoming_req)
    :match

    iex> cassette_req = %{
    ...>   "method" => "GET",
    ...>   "uri" => "https://api.example.com/sku/{{sku.0}}"
    ...> }
    iex> incoming_req = %{
    ...>   "method" => "POST",
    ...>   "uri" => "https://api.example.com/sku/{{sku.0}}"
    ...> }
    iex> match?(cassette_req, incoming_req)
    {:error, %{field: "method", expected: "GET", actual: "POST"}}