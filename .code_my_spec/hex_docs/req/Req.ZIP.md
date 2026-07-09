# Req.ZIP

ZIP archive decoding.

## decode/1

Decodes a ZIP archive `binary` into a list of `{name, contents}` entries.

Returns `{:ok, entries}` or `{:error, exception}`.