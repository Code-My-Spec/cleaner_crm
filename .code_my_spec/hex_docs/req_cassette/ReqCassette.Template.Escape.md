# ReqCassette.Template.Escape

Handles escaping and unescaping of template markers to prevent collisions with literal braces.

When data contains literal `{{` or `}}` sequences, they need to be escaped to avoid
confusion with template markers like `{{sku.0}}`. This module provides escape/unescape
functions to handle this safely.

## Problem

If actual response data contains `{{special}}`, it would be confused with a template marker.

## Solution

Escape literal braces during template creation:
- `{{` → `\{\{`
- `}}` → `\}\}`
- `\` → `\\` (escape the escape character)

## Examples

    iex> escape("literal {{value}} and normal text")
    "literal \\{\\{value\\}\\} and normal text"

    iex> unescape("literal \\{\\{value\\}\\} and normal text")
    "literal {{value}} and normal text"

    # Template markers are not escaped (handled by replacer module)
    iex> escape("SKU {{sku.0}} is active")
    "SKU {{sku.0}} is active"  # Markers stay as-is

    # But literal braces in data are escaped
    iex> data = ~s({"code": "{{special}}", "sku": "1234"})
    iex> escape(data)
    ~s({"code": "\\{\\{special\\}\\}", "sku": "1234"})

## Escaping Order

When creating templates:
1. Escape literal braces in original content first
2. Then create template markers (by replacer module)

When applying templates:
1. Substitute template markers with values (by replacer module)
2. Then unescape literal braces

This ensures template markers are never confused with literal data.

## escape/1

Escapes literal `{{`, `}}`, and `\` sequences in a string.

## Parameters

- `string` - The string to escape

## Returns

String with escaped sequences

## Examples

    iex> escape("normal text")
    "normal text"

    iex> escape("has {{literal}} braces")
    "has \\{\\{literal\\}\\} braces"

    iex> escape("backslash \\ here")
    "backslash \\\\ here"

    iex> escape("both \\ and {{value}}")
    "both \\\\ and \\{\\{value\\}\\}"

## unescape/1

Unescapes previously escaped `{{`, `}}`, and `\` sequences.

## Parameters

- `string` - The string with escaped sequences

## Returns

String with sequences restored to original form

## Examples

    iex> unescape("normal text")
    "normal text"

    iex> unescape("has \\{\\{literal\\}\\} braces")
    "has {{literal}} braces"

    iex> unescape("backslash \\\\ here")
    "backslash \\ here"

    iex> unescape("both \\\\ and \\{\\{value\\}\\}")
    "both \\ and {{value}}"

## escape_json/1

Escapes literal braces in a JSON structure recursively.

This is used for JSON bodies where we need to escape literal braces
in string values while preserving the JSON structure.

## Parameters

- `data` - The data structure (map, list, or primitive)

## Returns

Data structure with escaped string values

## Examples

    iex> escape_json(%{"key" => "{{value}}"})
    %{"key" => "\\{\\{value\\}\\}"}

    iex> escape_json(%{"nested" => %{"key" => "{{test}}"}})
    %{"nested" => %{"key" => "\\{\\{test\\}\\}"}}

    iex> escape_json(["{{item}}", "normal", 123])
    ["\\{\\{item\\}\\}", "normal", 123]

## unescape_json/1

Unescapes literal braces in a JSON structure recursively.

## Parameters

- `data` - The data structure (map, list, or primitive)

## Returns

Data structure with unescaped string values

## Examples

    iex> unescape_json(%{"key" => "\\{\\{value\\}\\}"})
    %{"key" => "{{value}}"}

    iex> unescape_json(%{"nested" => %{"key" => "\\{\\{test\\}\\}"}})
    %{"nested" => %{"key" => "{{test}}"}}

    iex> unescape_json(["\\{\\{item\\}\\}", "normal", 123])
    ["{{item}}", "normal", 123]