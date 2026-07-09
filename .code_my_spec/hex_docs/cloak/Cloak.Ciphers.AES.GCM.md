# Cloak.Ciphers.AES.GCM

A `Cloak.Cipher` which encrypts values with the AES cipher in GCM (block) mode.
Internally relies on Erlang's `:crypto.block_encrypt/4`.

## encrypt/2

Callback implementation for `Cloak.Cipher`. Encrypts a value using
AES in GCM mode.

Generates a random IV for every encryption, and prepends the key tag, IV,
and ciphertag to the beginning of the ciphertext. The format can be
diagrammed like this:

    +----------------------------------------------------------+----------------------+
    |                          HEADER                          |         BODY         |
    +-------------------+---------------+----------------------+----------------------+
    | Key Tag (n bytes) | IV (n bytes)  | Ciphertag (16 bytes) | Ciphertext (n bytes) |
    +-------------------+---------------+----------------------+----------------------+
    |                   |_________________________________
    |                                                     |
    +---------------+-----------------+-------------------+
    | Type (1 byte) | Length (1 byte) | Key Tag (n bytes) |
    +---------------+-----------------+-------------------+

The `Key Tag` component of the header breaks down into a `Type`, `Length`,
and `Value` triplet for easy decoding.

**Important**: Because a random IV is used for every encryption, `encrypt/2`
will not produce the same ciphertext twice for the same value.

## decrypt/2

Callback implementation for `Cloak.Cipher`. Decrypts a value
encrypted with AES in GCM mode.

## can_decrypt?/2

Callback implementation for `Cloak.Cipher`. Determines whether this module
can decrypt the given ciphertext.