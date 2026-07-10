# ReqCassette.Template.Presets

Built-in pattern presets for common API providers.

Presets provide pre-configured regex patterns for dynamic values
commonly found in specific API responses. This is especially useful
for LLM APIs where message IDs, tool use IDs, and request IDs change
with every call.

## Available Presets

- `:anthropic` - Anthropic Claude API patterns (`msg_*`, `toolu_*`, `req_*`)
- `:openai` - OpenAI API patterns (`chatcmpl-*`, `call_*`)
- `:llm` - All LLM provider patterns combined
- `:common` - Common patterns (UUIDs, ISO timestamps)

## Usage

Presets can be used alone or combined with custom patterns:

    # Use preset only
    template: [preset: :anthropic]

    # Preset with additional patterns (explicit patterns override preset)
    template: [preset: :anthropic, patterns: [order_id: ~r/ORD-\d+/]]

    # Combined LLM preset for multi-provider support
    template: [preset: :llm]

## Pattern Details

### Anthropic Patterns

| Pattern | Regex | Example |
|---------|-------|---------|
| `msg_id` | `msg_[a-zA-Z0-9]+` | `msg_01XzW7o3s58J6KauMpLBFtEf` |
| `toolu_id` | `toolu_[a-zA-Z0-9]+` | `toolu_01K6u2Q9D6W7heeVvKAcLcAJ` |
| `anthropic_request_id` | `req_[a-zA-Z0-9]+` | `req_01234abcdef` |

### OpenAI Patterns

| Pattern | Regex | Example |
|---------|-------|---------|
| `chatcmpl_id` | `chatcmpl-[a-zA-Z0-9]+` | `chatcmpl-abc123def456` |
| `call_id` | `call_[a-zA-Z0-9]+` | `call_abc123` |

### Common Patterns

| Pattern | Regex | Example |
|---------|-------|---------|
| `uuid` | UUID v4 format | `550e8400-e29b-41d4-a716-446655440000` |
| `iso_timestamp` | ISO 8601 datetime | `2025-01-15T10:30:00Z` |

## get/1

Returns patterns for the given preset name.

## Parameters

- `preset_name` - One of `:anthropic`, `:openai`, `:llm`, or `:common`

## Returns

- `{:ok, patterns}` - A keyword list of `{name, regex}` pairs
- `{:error, {:unknown_preset, name}}` - If the preset is not recognized

## Examples

    iex> {:ok, patterns} = ReqCassette.Template.Presets.get(:anthropic)
    iex> Keyword.keys(patterns)
    [:msg_id, :toolu_id, :anthropic_request_id]

    iex> ReqCassette.Template.Presets.get(:unknown)
    {:error, {:unknown_preset, :unknown}}

## available/0

Lists all available preset names.

## Examples

    iex> ReqCassette.Template.Presets.available()
    [:anthropic, :openai, :llm, :common]

## get!/1

Returns patterns for the given preset name, raising on error.

## Parameters

- `preset_name` - One of `:anthropic`, `:openai`, `:llm`, or `:common`

## Returns

A keyword list of `{name, regex}` pairs.

## Raises

`ArgumentError` if the preset is not recognized.

## Examples

    iex> patterns = ReqCassette.Template.Presets.get!(:anthropic)
    iex> Keyword.keys(patterns)
    [:msg_id, :toolu_id, :anthropic_request_id]