# Tesla.Middleware.Compression.Error

Raised when a response cannot be safely decompressed.

The `:reason` field is one of:

- `:max_body_size_exceeded` - the decompressed body grew past the configured
  `:max_body_size`.
- `:multiple_codecs` - the response advertised more than one supported
  `content-encoding` codec (e.g. `gzip, gzip`).
- `{:zlib, term}` - the underlying `:zlib` stream returned an error.