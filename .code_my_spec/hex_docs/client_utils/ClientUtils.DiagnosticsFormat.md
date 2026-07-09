# ClientUtils.DiagnosticsFormat

Serializes `Mix.Task.Compiler.Diagnostic` structs to JSON-compatible maps.

## to_jsonl/1

Encodes a list of diagnostics as JSONL (one JSON object per line).

## to_map/1

Converts a diagnostic struct to a plain map suitable for JSON encoding.