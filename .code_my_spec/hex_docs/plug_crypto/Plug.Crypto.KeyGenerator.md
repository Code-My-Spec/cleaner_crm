# Plug.Crypto.KeyGenerator

`KeyGenerator` implements PBKDF2 (Password-Based Key Derivation Function 2),
part of PKCS #5 v2.0 (Password-Based Cryptography Specification).

It can be used to derive a number of keys for various purposes from a given
secret. This lets applications have a single secure secret, but avoid reusing
that key in multiple incompatible contexts.

The returned key is a binary. You may invoke functions in the `Base` module,
such as `Base.url_encode64/2`, to convert this binary into a textual
representation.

See http://tools.ietf.org/html/rfc2898#section-5.2

## generate/3

Returns a derived key suitable for use.

## Options

  * `:iterations` - defaults to 1000 (increase to at least 2^16 if used for passwords);
  * `:length`     - a length in octets for the derived key. Defaults to 32;
  * `:digest`     - an hmac function to use as the pseudo-random function. Defaults to `:sha256`;
  * `:cache`      - an ETS table name to be used as cache.
    Only use an ETS table as cache if the secret and salt is a bound set of values.
    For example: `:ets.new(:your_name, [:named_table, :public, read_concurrency: true])`