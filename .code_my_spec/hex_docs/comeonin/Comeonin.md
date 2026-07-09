# Comeonin

Defines a behaviour for higher-level password hashing functions.

## __using__/1

Runs the password hash function, but always returns false.

This function is intended to make it more difficult for any potential
attacker to find valid usernames by using timing attacks. This function
is only useful if it is used as part of a policy of hiding usernames.