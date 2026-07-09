# Plug.Crypto

Namespace and module for crypto-related functionality.

For low-level functionality, see `Plug.Crypto.KeyGenerator`,
`Plug.Crypto.MessageEncryptor`, and `Plug.Crypto.MessageVerifier`.

## prune_args_from_stacktrace/1

Prunes the stacktrace to remove any argument trace.

This is useful when working with functions that receives secrets
and we want to make sure those secrets do not leak on error messages.

## non_executable_binary_to_term/2

A restricted version of `:erlang.binary_to_term/2` that forbids
*executable* terms, such as anonymous functions.

The `opts` are given to the underlying `:erlang.binary_to_term/2`
call, with an empty list as a default.

By default this function does not restrict atoms, as an atom
interned in one node may not yet have been interned on another
(except for releases, which preload all code).

If you want to avoid atoms from being created, then you can pass
`[:safe]` as options, as that will also enable the safety mechanisms
from `:erlang.binary_to_term/2` itself.

## mask/2

Masks the token on the left with the token on the right.

Both tokens are required to have the same size.

## masked_compare/3

Compares the two binaries (one being masked) in constant-time to avoid
timing attacks.

It is assumed the right token is masked according to the given mask.

## secure_compare/2

Compares the two binaries in constant-time to avoid timing attacks.

See: http://codahale.com/a-lesson-in-timing-attacks/

## sign/4

Encodes and signs data into a token you can send to clients.

    Plug.Crypto.sign(conn.secret_key_base, "user-secret", {:elixir, :terms})

A key will be derived from the secret key base and the given user secret.
The key will also be cached for performance reasons on future calls.

## Options

  * `:key_iterations` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 1000
  * `:key_length` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 32
  * `:key_digest` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to `:sha256`
  * `:signed_at` - set the timestamp of the token in seconds.
    Defaults to `System.os_time(:millisecond)`
  * `:max_age` - the default maximum age of the token. Defaults to
    `86400` seconds (1 day) and it may be overridden on `verify/4`.

## encrypt/4

Encodes, encrypts, and signs data into a token you can send to clients.

    Plug.Crypto.encrypt(conn.secret_key_base, "user-secret", {:elixir, :terms})

A key will be derived from the secret key base and the given user secret.
The key will also be cached for performance reasons on future calls.

## Options

  * `:key_iterations` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 1000
  * `:key_length` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 32
  * `:key_digest` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to `:sha256`
  * `:signed_at` - set the timestamp of the token in seconds.
    Defaults to `System.os_time(:millisecond)`
  * `:max_age` - the default maximum age of the token. Defaults to
    `86400` seconds (1 day) and it may be overridden on `decrypt/4`.

## verify/4

Decodes the original data from the token and verifies its integrity.

## Examples

In this scenario we will create a token, sign it, then provide it to a client
application. The client will then use this token to authenticate requests for
resources from the server. See `Plug.Crypto` summary for more info about
creating tokens.

    iex> user_id    = 99
    iex> secret     = "kjoy3o1zeidquwy1398juxzldjlksahdk3"
    iex> user_salt  = "user salt"
    iex> token      = Plug.Crypto.sign(secret, user_salt, user_id)

The mechanism for passing the token to the client is typically through a
cookie, a JSON response body, or HTTP header. For now, assume the client has
received a token it can use to validate requests for protected resources.

When the server receives a request, it can use `verify/4` to determine if it
should provide the requested resources to the client:

    iex> Plug.Crypto.verify(secret, user_salt, token, max_age: 86400)
    {:ok, 99}

In this example, we know the client sent a valid token because `verify/4`
returned a tuple of type `{:ok, user_id}`. The server can now proceed with
the request.

However, if the client had sent an expired or otherwise invalid token
`verify/4` would have returned an error instead:

    iex> Plug.Crypto.verify(secret, user_salt, expired, max_age: 86400)
    {:error, :expired}

    iex> Plug.Crypto.verify(secret, user_salt, invalid, max_age: 86400)
    {:error, :invalid}

## Options

  * `:max_age` - verifies the token only if it has been generated
    "max age" ago in seconds. Defaults to the max age signed in the
    token (86400)
  * `:key_iterations` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 1000
  * `:key_length` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 32
  * `:key_digest` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to `:sha256`

## decrypt/4

Decrypts the original data from the token and verifies its integrity.

## Options

  * `:max_age` - verifies the token only if it has been generated
    "max age" ago in seconds. A reasonable value is 1 day (86400
    seconds)
  * `:key_iterations` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 1000
  * `:key_length` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to 32
  * `:key_digest` - option passed to `Plug.Crypto.KeyGenerator`
    when generating the encryption and signing keys. Defaults to `:sha256`