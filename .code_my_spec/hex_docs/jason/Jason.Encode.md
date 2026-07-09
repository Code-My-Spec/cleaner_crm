# Jason.Encode

Utilities for encoding elixir values to JSON.

## value/2

Equivalent to calling the `Jason.Encoder.encode/2` protocol function.

Slightly more efficient for built-in types because of the internal dispatching.