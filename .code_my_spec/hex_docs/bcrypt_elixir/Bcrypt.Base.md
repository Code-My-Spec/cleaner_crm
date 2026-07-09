# Bcrypt.Base

Base module for the Bcrypt password hashing library.

## gen_salt/2

Generate a salt for use with the `hash_password` function.

The `:log_rounds` parameter determines the computational complexity
of the generation of the password hash. Its default is 12, the minimum is 4,
and the maximum is 31.

The `:legacy` option is for generating salts with the old `$2a$` prefix.
Only use this option if you need to generate hashes that are then checked
by older libraries.

## hash_password/2

Hash a password using Bcrypt.

## gensalt_nif/3

Generate a salt for use with Bcrypt.

## hash_nif/2

Hash the password and salt with the Bcrypt hashing algorithm.

## checkpass_nif/2

Verify the password by comparing it with the stored hash.