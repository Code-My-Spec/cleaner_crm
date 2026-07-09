# HPAX

Support for the HPACK header compression algorithm.

This module provides support for the HPACK header compression algorithm used mainly in HTTP/2.

## Encoding and decoding contexts

The HPACK algorithm requires both

  * an encoding context on the encoder side
  * a decoding context on the decoder side

These contexts are semantically different but structurally the same. In HPACK they are
implemented as **HPACK tables**. This library uses the name "tables" everywhere internally

HPACK tables can be created through the `new/1` function.

## new/1

Creates a new HPACK table.

Same as `new/2` with default options.

## new/2

Create a new HPACK table that can be used as encoding or decoding context.

See the "Encoding and decoding contexts" section in the module documentation.

`max_table_size` is the maximum table size (in bytes) for the newly created table.

## Options

This function accepts the following `options`:

  * `:huffman_encoding` - (since 0.2.0) `:always` or `:never`. If `:always`,
    then HPAX will always encode headers using Huffman encoding. If `:never`,
    HPAX will not use any Huffman encoding. Defaults to `:never`.

## Examples

    encoding_context = HPAX.new(4096)

## decode/2

Decodes a header block fragment (HBF) through a given table.

If decoding is successful, this function returns a `{:ok, headers, updated_table}` tuple where
`headers` is a list of decoded headers, and `updated_table` is the updated table. If there's
an error in decoding, this function returns `{:error, reason}`.

## Examples

    decoding_context = HPAX.new(1000)
    hbf = get_hbf_from_somewhere()
    HPAX.decode(hbf, decoding_context)
    #=> {:ok, [{":method", "GET"}], decoding_context}

## encode/2

Encodes a list of headers through the given table.

Returns a two-element tuple where the first element is a binary representing the encoded headers
and the second element is an updated table.

## Examples

    headers = [{:store, ":authority", "https://example.com"}]
    encoding_context = HPAX.new(1000)
    HPAX.encode(headers, encoding_context)
    #=> {iodata, updated_encoding_context}

## encode/3

Encodes a list of headers through the given table, applying the same `action` to all of them.

This function is the similar to `encode/2`, but `headers` are `{name, value}` tuples instead,
and the same `action` is applied to all headers.

  ## Examples

    headers = [{":authority", "https://example.com"}]
    encoding_context = HPAX.new(1000)
    HPAX.encode(:store, headers, encoding_context)
    #=> {iodata, updated_encoding_context}