# Tesla.Middleware.Compression

Compress requests and decompress responses.

Supports "gzip" and "deflate" encodings using Erlang's built-in `:zlib` module.

## Examples

```elixir
defmodule MyClient do
  def client do
    Tesla.client([
      {Tesla.Middleware.Compression, format: "gzip", max_body_size: 32 * 1024 * 1024}
    ])
  end
end
```

## Options

- `:format` - request compression format, `"gzip"` (default) or `"deflate"`.
- `:max_body_size` - **required.** Maximum size, in bytes, of any decompressed
  response body. Pass a positive integer (e.g. `32 * 1024 * 1024`) or `:infinity`
  to disable the cap explicitly. Responses that decompress to more bytes raise
  `Tesla.Middleware.Compression.Error` with reason `:max_body_size_exceeded`.

## Security

Decompressing untrusted response bodies without a size cap is a denial-of-service
vector ("zip bomb"): a small response can inflate into gigabytes of memory and
exhaust the BEAM heap. To make that impossible by construction this middleware:

- requires `:max_body_size` to be set so the cap is always a conscious choice;
- streams inflation through `:zlib.safeInflate/2` and aborts as soon as the
  cap is exceeded, before the full body is materialised in memory; and
- rejects responses that advertise more than one supported compression codec
  in `content-encoding`, since stacked codecs are almost exclusively a bomb
  pattern and cannot be safely bounded by a single per-layer cap.

## compress/2

Compress request.

It is used by `Tesla.Middleware.CompressRequest`.

## decompress/2

Decompress response.

It is used by `Tesla.Middleware.DecompressResponse`.