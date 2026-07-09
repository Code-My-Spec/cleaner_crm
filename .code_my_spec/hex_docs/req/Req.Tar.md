# Req.Tar

Tar archive decoding.

## decode/1

Decodes a tar archive `binary` into a list of `{name, contents}` entries.

The binary may be a plain tar archive or a gzip-compressed one (`.tar.gz`/`.tgz`); the
compression is detected automatically.

Returns `{:ok, entries}` or `{:error, exception}`.