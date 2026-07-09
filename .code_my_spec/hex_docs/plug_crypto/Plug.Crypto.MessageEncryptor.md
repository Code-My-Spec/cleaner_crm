# Plug.Crypto.MessageEncryptor



## encrypt/4

Encrypts a message using authenticated encryption.

The `sign_secret` is currently only used on decryption
for backwards compatibility.

A custom authentication message can be provided.
It defaults to "A128GCM" for backwards compatibility.

## decrypt/4

Decrypts a message using authenticated encryption.