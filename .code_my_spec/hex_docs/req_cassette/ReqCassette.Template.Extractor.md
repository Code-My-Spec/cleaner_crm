# ReqCassette.Template.Extractor

Extracts template variables from requests and responses using regex patterns.

This module scans specific parts of HTTP messages (URI, query params, body) to find
values matching the configured patterns, returning them in a consistent order for
positional template markers like `{{var.0}}`, `{{var.1}}`.

## Extraction Scope

Patterns are applied to:

1. **URI Path** - The path component of the URL
2. **Query Parameters** - URL query string parameters (sorted)
3. **Request/Response Bodies** - The body content (text, JSON, or blob)

**NOT scanned:**
- Headers (to prevent accidental exposure of auth tokens)
- HTTP Method
- Status Code

## Extraction Order

Values are extracted in this specific order to ensure predictable positional indexing:

1. URI path (left to right)
2. Query parameters (alphabetically sorted by key)
3. Request/response body (for JSON: depth-first traversal)

This ensures `{{order_id.0}}`, `{{order_id.1}}`, etc. map consistently.

## Examples

    # Basic extraction from request body
    iex> patterns = %{sku: ~r/\d{4}-\d{4}/}
    iex> request = %{
    ...>   "uri" => "https://api.example.com/products",
    ...>   "query_string" => "",
    ...>   "body" => "Get SKU 0234-3455 and SKU 0344-4456"
    ...> }
    iex> extract_from_request(request, patterns)
    %{sku: ["0234-3455", "0344-4456"]}

    # Extraction from multiple scopes
    iex> patterns = %{order_id: ~r/ORD-\d+/}
    iex> request = %{
    ...>   "uri" => "https://api.example.com/orders/ORD-11111",
    ...>   "query_string" => "ref=ORD-22222",
    ...>   "body_json" => %{"related" => "ORD-33333"}
    ...> }
    iex> extract_from_request(request, patterns)
    %{order_id: ["ORD-11111", "ORD-22222", "ORD-33333"]}

    # Multiple patterns
    iex> patterns = %{
    ...>   sku: ~r/SKU-\d+/,
    ...>   order: ~r/ORD-\d+/
    ...> }
    iex> request = %{
    ...>   "uri" => "https://api.example.com/orders/ORD-123",
    ...>   "query_string" => "",
    ...>   "body" => "SKU-456 for ORD-123"
    ...> }
    iex> extract_from_request(request, patterns)
    %{sku: ["SKU-456"], order: ["ORD-123", "ORD-123"]}

## Response Scanning

The `scan_response/2` function determines which request variables also appear
in the response, so we know which ones to template:

    iex> request_vars = %{sku: ["0234-3455", "0344-4456"]}
    iex> response = %{"body_json" => %{"result" => "SKU 0234-3455 found"}}
    iex> scan_response(response, request_vars)
    MapSet.new(["sku.0"])

## Pattern Overlap

When multiple patterns match the same text, the most specific (longest match) wins:

    iex> patterns = %{
    ...>   id: ~r/\d+/,
    ...>   sku: ~r/SKU-\d{4}/
    ...> }
    iex> extract_from_string("Item SKU-1234", patterns)
    %{sku: ["SKU-1234"]}  # sku pattern wins over id

## extract_from_request/2

Extracts template variables from a request using the provided patterns.

Scans URI path, query parameters, and body in that order, collecting all matches
for each pattern.

## Parameters

- `request` - Request map with "uri", "query_string", and body fields
- `patterns` - Map of `%{pattern_name => regex}`, e.g., `%{sku: ~r/\d{4}-\d{4}/}`

## Returns

Map of `%{pattern_name => [match1, match2, ...]}` with matches in extraction order

## Examples

    iex> patterns = %{sku: ~r/\d{4}-\d{4}/}
    iex> request = %{
    ...>   "uri" => "https://api.example.com/products/1234-5678",
    ...>   "query_string" => "related=9999-8888",
    ...>   "body" => "Also check 7777-6666"
    ...> }
    iex> extract_from_request(request, patterns)
    %{sku: ["1234-5678", "9999-8888", "7777-6666"]}

## extract_from_response/2

Extracts template variables from a response using the provided patterns.

## Parameters

- `response` - Response map with body fields
- `patterns` - Map of `%{pattern_name => regex}`

## Returns

Map of `%{pattern_name => [match1, match2, ...]}`

## Examples

    iex> patterns = %{sku: ~r/\d{4}-\d{4}/}
    iex> response = %{
    ...>   "body_json" => %{"sku" => "1234-5678", "count" => 5}
    ...> }
    iex> extract_from_response(response, patterns)
    %{sku: ["1234-5678"]}

## scan_response/2

Scans a response to find which request variables appear in it.

This determines which variables should be templated in both request and response
(true template variables) vs. which only appear in request (wildcards).

## Parameters

- `response` - Response map with body fields
- `request_vars` - Map of variables extracted from request, e.g., `%{sku: ["1234", "5678"]}`

## Returns

MapSet of variable references that appear in response, e.g., `MapSet.new(["sku.0", "sku.1"])`

## Examples

    iex> request_vars = %{sku: ["1234-5678", "9999-8888"]}
    iex> response = %{"body" => "Found SKU 1234-5678"}
    iex> scan_response(response, request_vars)
    MapSet.new(["sku.0"])

    iex> request_vars = %{sku: ["1234-5678", "9999-8888"]}
    iex> response = %{"body_json" => %{"items" => ["1234-5678", "9999-8888"]}}
    iex> scan_response(response, request_vars)
    MapSet.new(["sku.0", "sku.1"])

## extract_from_string/2

Extracts matches from a string using the provided patterns.

## Parameters

- `string` - The string to scan
- `patterns` - Map of `%{pattern_name => regex}`

## Returns

Map of `%{pattern_name => [match1, match2, ...]}`

## Examples

    iex> patterns = %{sku: ~r/SKU-\d+/, order: ~r/ORD-\d+/}
    iex> extract_from_string("Order ORD-123 for SKU-456", patterns)
    %{sku: ["SKU-456"], order: ["ORD-123"]}

    iex> patterns = %{code: ~r/\d{4}/}
    iex> extract_from_string("Codes 1234 and 5678", patterns)
    %{code: ["1234", "5678"]}