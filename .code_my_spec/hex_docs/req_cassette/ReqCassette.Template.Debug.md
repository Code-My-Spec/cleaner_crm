# ReqCassette.Template.Debug

Formats debugging information for template matching failures and provides
optional logging during template extraction and matching.

When a template match fails during replay, this module provides detailed diff output
to help developers understand what went wrong and how to fix it.

## Debug Logging

Enable debug logging by setting `debug: true` in template options:

    template: [preset: :anthropic, debug: true]

This will log:
- Pattern extraction results during recording
- Template match attempts during replay

## Example Output

```
Template match failed for cassette "sku_lookup"

Expected template structure:
  Method: GET
  URI: https://api.example.com/sku/{{sku.0}}
  Body: List SKU {{sku.0}} separated from SKU {{sku.1}}

Incoming request (templated):
  Method: GET
  URI: https://api.example.com/sku/{{sku.0}}
  Body: List SKU {{sku.0}} but exclude SKU {{sku.1}}
                             ^^^^^^^^^^^
                             Difference detected here

Extracted variables:
  sku.0 = "6785-9443"
  sku.1 = "3488-3234"

Hint: The request structure changed. Update cassette or adjust patterns.
```

## format_diff/4

Formats a detailed diff for a template match failure.

## Parameters

- `cassette_request` - The templated request from the cassette
- `incoming_request` - The templated incoming request
- `diff` - The diff information from the matcher (what field differs)
- `variables` - The extracted variables from the incoming request

## Returns

A formatted string with the diff information

## Examples

    iex> cassette_req = %{
    ...>   "method" => "GET",
    ...>   "uri" => "https://api.example.com/sku/{{sku.0}}",
    ...>   "body" => "Get {{sku.0}}"
    ...> }
    iex> incoming_req = %{
    ...>   "method" => "POST",
    ...>   "uri" => "https://api.example.com/sku/{{sku.0}}",
    ...>   "body" => "Get {{sku.0}}"
    ...> }
    iex> diff = %{field: "method", expected: "GET", actual: "POST"}
    iex> variables = %{sku: ["1234"]}
    iex> message = format_diff(cassette_req, incoming_req, diff, variables)
    iex> String.contains?(message, "Method mismatch")
    true

## log_extraction/3

Logs pattern extraction results during recording.

When `enabled` is true, logs the patterns used and variables extracted.
When `enabled` is false, this is a no-op.

## Parameters

- `variables` - Map of extracted variables (e.g., `%{sku: ["1234-5678"]}`)
- `patterns` - Map of pattern names to regexes
- `enabled` - Whether debug logging is enabled

## Examples

    iex> log_extraction(%{sku: ["1234"]}, %{sku: ~r/\d{4}/}, true)
    :ok

## log_match_attempt/5

Logs a template match attempt during replay.

When `enabled` is true, logs whether the match succeeded or failed,
with detailed diff information on failure.
When `enabled` is false, this is a no-op.

## Parameters

- `cassette_request` - The templated request from the cassette
- `incoming_request` - The templated incoming request
- `result` - Either `:match` or `{:error, diff}`
- `variables` - The extracted variables from the incoming request
- `enabled` - Whether debug logging is enabled

## Examples

    iex> log_match_attempt(%{...}, %{...}, :match, %{sku: ["1234"]}, true)
    :ok

## format_variables/1

Formats extracted variables for display.

This is a public helper that can be reused by other modules
(e.g., Mix tasks for cassette inspection).

## Parameters

- `variables` - Map of variable names to lists of values

## Returns

A formatted string showing each variable and its values.

## Examples

    iex> format_variables(%{sku: ["1234", "5678"], order_id: ["ORD-1"]})
    "  sku.0 = \"1234\"\n  sku.1 = \"5678\"\n  order_id.0 = \"ORD-1\""

## format_request/1

Formats a request summary for display.

This is a public helper that can be reused by other modules
(e.g., Mix tasks for cassette inspection).

## Parameters

- `request` - A request map with method, uri, query_string, and body fields

## Returns

A formatted string summarizing the request.