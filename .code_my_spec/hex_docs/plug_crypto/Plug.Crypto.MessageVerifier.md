# Plug.Crypto.MessageVerifier

`MessageVerifier` makes it easy to generate and verify messages
which are signed to prevent tampering.

For example, the cookie store uses this verifier to send data
to the client. The data can be read by the client, but cannot be
tampered with.

The message and its verification are base64url encoded and returned
to you.

The current algorithm used is HMAC-SHA, with SHA256, SHA384, and
SHA512 as supported digest types.

## sign/3

Signs a message according to the given secret.

## verify/2

Decodes and verifies the encoded binary was not tampered with.