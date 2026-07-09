# Gettext.Compiler



## warn_if_domain_contains_slashes/1

Logs a warning via `Logger.error/1` if `domain` contains slashes.

This function is called by `lgettext` and `lngettext`. It could make sense to
make this function raise an error since slashes in domains are not supported,
but we decided not to do so and to only emit a warning since the expected
behaviour for Gettext functions/macros when the domain or message is not
known is to return the original string (msgid) and raising here would break
that contract.