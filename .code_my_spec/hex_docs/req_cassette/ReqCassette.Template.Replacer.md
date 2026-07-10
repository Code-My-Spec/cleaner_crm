# ReqCassette.Template.Replacer

Creates and applies template markers by replacing values with `{{var.N}}` placeholders.

This module handles:
- Creating templates from original content by replacing extracted values with markers
- Applying templates by substituting new values into markers
- Type safety for JSON bodies (only template string values)
- Escape handling for literal braces

## Template Marker Format

Template markers use the format `{{name.index}}` where:
- `name` is the pattern name (e.g., `sku`, `order_id`)
- `index` is the instance identifier for each unique value (value-based, not position-based)

**Important:** Duplicate values get the same index!

Examples:
```
# Different values → different indices
Variables: %{sku: ["0234-3455", "0344-4456"]}
Markers: {{sku.0}}, {{sku.1}}

# Duplicate values → same index
Variables: %{sku: ["0234-3455", "0234-3455"]}
Text: "SKU 0234-3455 and SKU 0234-3455 again"
Result: "SKU {{sku.0}} and {{sku.0}} again"
```

The index identifies the unique VALUE, not its position. This means:
- Same value appearing multiple times → all get the same marker
- Only unique values get different indices

## Type Safety for JSON

When templating JSON bodies:
- **String values** - Templated: `"SKU {{sku.0}}"`
- **Numbers** - NOT templated: `5` stays as `5`
- **Booleans** - NOT templated: `true` stays as `true`
- **Null** - NOT templated: `null` stays as `null`
- **Arrays** - Elements processed recursively
- **Objects** - Values processed recursively, keys optionally

This ensures generated JSON is always valid and type-safe.

## Examples

    # Create text template
    iex> variables = %{sku: ["1234-5678", "9999-8888"]}
    iex> content = "Get SKU 1234-5678 and exclude SKU 9999-8888"
    iex> create_template(content, variables)
    "Get SKU {{sku.0}} and exclude SKU {{sku.1}}"

    # Create JSON template (only strings templated)
    iex> variables = %{sku: ["1234-5678"]}
    iex> json = %{"sku" => "1234-5678", "count" => 5, "active" => true}
    iex> create_json_template(json, variables)
    %{"sku" => "{{sku.0}}", "count" => 5, "active" => true}

    # Apply template
    iex> template = "Get SKU {{sku.0}} and exclude SKU {{sku.1}}"
    iex> variables = %{sku: ["5555-6666", "7777-8888"]}
    iex> apply_template(template, variables)
    "Get SKU 5555-6666 and exclude SKU 7777-8888"

## Options

- `:scope` - Which variables to template:
  - `:all` - Template all variables (default)
  - MapSet of var references like `MapSet.new(["sku.0"])` - Template only these
- `:allow_key_templates` - Allow templating JSON object keys (default: false)

## create_template_from_data/3

Creates a template from request/response data by replacing values with markers.

This is the main entry point that handles both JSON and text bodies.

## Parameters

- `data` - Request or response map
- `variables` - Extracted variables map like `%{sku: ["1234", "5678"]}`
- `opts` - Options:
  - `:scope` - `:all` or MapSet of variable references to template
  - `:allow_key_templates` - Allow JSON key templating (default: false)

## Returns

Data map with values replaced by template markers

## Examples

    iex> data = %{"body" => "Get SKU 1234-5678"}
    iex> variables = %{sku: ["1234-5678"]}
    iex> create_template_from_data(data, variables)
    %{"body" => "Get SKU {{sku.0}}"}

    iex> data = %{"body_json" => %{"sku" => "1234-5678", "count" => 5}}
    iex> variables = %{sku: ["1234-5678"]}
    iex> create_template_from_data(data, variables)
    %{"body_json" => %{"sku" => "{{sku.0}}", "count" => 5}}

## create_json_template/3

Creates a template from JSON data with type safety.

Only string values are templated. Numbers, booleans, null, and non-string types
are preserved as-is to ensure valid JSON output.

## Parameters

- `json_data` - The JSON data (map or list)
- `variables` - Extracted variables
- `opts` - Options (`:scope`, `:allow_key_templates`)

## Returns

JSON data with string values replaced by template markers

## Examples

    iex> json = %{"sku" => "1234", "count" => 5, "active" => true}
    iex> variables = %{sku: ["1234"]}
    iex> create_json_template(json, variables)
    %{"sku" => "{{sku.0}}", "count" => 5, "active" => true}

    iex> json = %{"items" => [%{"id" => "ABC"}, %{"id" => "XYZ"}]}
    iex> variables = %{id: ["ABC", "XYZ"]}
    iex> create_json_template(json, variables)
    %{"items" => [%{"id" => "{{id.0}}"}, %{"id" => "{{id.1}}"}]}

## create_template/3

Creates a template from text content by replacing values with markers.

Unlike JSON templating, this can replace values anywhere in the string.

## Parameters

- `content` - The text content
- `variables` - Extracted variables
- `opts` - Options (`:scope`)

## Returns

Text with values replaced by template markers

## Examples

    iex> content = "Order ORD-123 ships with SKU-456"
    iex> variables = %{order: ["ORD-123"], sku: ["SKU-456"]}
    iex> create_template(content, variables)
    "Order {{order.0}} ships with {{sku.0}}"

## apply_template_to_data/2

Applies a template by substituting variables with new values.

This is used during replay to inject new request values into the templated response.

## Parameters

- `data` - Templated data map (request or response)
- `variables` - New variables to substitute, e.g., `%{sku: ["5555", "6666"]}`

## Returns

Data with template markers replaced by actual values

## Examples

    iex> data = %{"body" => "Get SKU {{sku.0}}"}
    iex> variables = %{sku: ["9999"]}
    iex> apply_template_to_data(data, variables)
    %{"body" => "Get SKU 9999"}

    iex> data = %{"body_json" => %{"sku" => "{{sku.0}}", "count" => 5}}
    iex> variables = %{sku: ["7777"]}
    iex> apply_template_to_data(data, variables)
    %{"body_json" => %{"sku" => "7777", "count" => 5}}

## substitute_in_json/2

Substitutes template markers in JSON data recursively.

## Parameters

- `json_data` - JSON data with template markers
- `variables` - Variables to substitute

## Returns

JSON data with markers replaced by values

## Examples

    iex> json = %{"id" => "{{sku.0}}", "count" => 5}
    iex> variables = %{sku: ["9999"]}
    iex> substitute_in_json(json, variables)
    %{"id" => "9999", "count" => 5}

## replace_in_string/3

Replaces values with template markers in a string.

## Parameters

- `string` - The string to template
- `variables` - Variables to replace
- `opts` - Options (`:scope`)

## Returns

String with values replaced by markers

## Examples

    iex> replace_in_string("Get 1234 and 5678", %{sku: ["1234", "5678"]})
    "Get {{sku.0}} and {{sku.1}}"

## substitute_in_string/2

Substitutes template markers with actual values in a string.

## Parameters

- `string` - String with template markers
- `variables` - Variables to substitute

## Returns

String with markers replaced by values, and literal braces unescaped

## Examples

    iex> substitute_in_string("Get {{sku.0}}", %{sku: ["9999"]})
    "Get 9999"

    iex> substitute_in_string("{{sku.0}} and {{sku.1}}", %{sku: ["AAA", "BBB"]})
    "AAA and BBB"