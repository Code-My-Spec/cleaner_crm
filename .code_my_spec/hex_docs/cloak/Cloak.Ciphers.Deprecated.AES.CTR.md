# Cloak.Ciphers.Deprecated.AES.CTR

DEPRECATED version of the `Cloak.Ciphers.AES.CTR` cipher, for use in
migrating existing data to the new format used by `Cloak.Ciphers.AES.CTR`.

## Rationale

The old `Cloak.AES.CTR` cipher used the following format for ciphertext:

    +---------------------------------------------------------+----------------------+
    |                         HEADER                          |         BODY         |
    +----------------------+------------------+---------------+----------------------+
    | Module Tag (n bytes) | Key Tag (1 byte) | IV (16 bytes) | Ciphertext (n bytes) |
    +----------------------+------------------+---------------+----------------------+

The new `Cloak.Ciphers.AES.CTR` implementation no longer prepends the "Module Tag"
component, and uses a new format as described in its docs. This cipher can
assist in upgrading old ciphertext to the new format.

See the [Upgrading from 0.6.x](0.6.x_to_0.7.x.html) guide for usage.