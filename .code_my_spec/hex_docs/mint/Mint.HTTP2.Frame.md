# Mint.HTTP2.Frame



## decode_next/2

Decodes the next frame of the given binary.

Returns `{:ok, frame, rest}` if successful, `{:error, reason}` if not.

## encode/1

Encodes the given `frame`.