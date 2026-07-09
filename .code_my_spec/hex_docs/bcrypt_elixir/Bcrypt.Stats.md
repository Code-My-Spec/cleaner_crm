# Bcrypt.Stats

Module to provide statistics for the Bcrypt password hashing function.

The `report/1` function in this module can be used to help you configure
Bcrypt.

## Configuration

There is one configuration option for Bcrypt - `:log_rounds`.
Increasing this value will increase the complexity, and time
taken, of the Bcrypt function.

Increasing the time that a password hash function takes makes it more
difficult for an attacker to find the correct password. However, the
amount of time a valid user has to wait also needs to be taken into
consideration when setting the number of log rounds.

The correct number of log rounds depends on circumstances specific to your
use case, such as what level of security you want, how often the user
has to log in, and the hardware you are using. However, for password
hashing, we do not recommend setting the number of log rounds to anything
less than 12.

## report/1

Hash a password with Bcrypt and print out a report.

This function hashes a password, and salt, with `Bcrypt.Base.hash_password/2`
and prints out statistics which can help you choose how many to configure
Bcrypt.

## Options

There are three options:

  * `:log_rounds` - the number of log rounds
    * the default is 12
  * `:password` - the password used
    * the default is "password"
  * `:salt` - the salt used
    * the default is the output of `Bcrypt.Base.gen_salt`