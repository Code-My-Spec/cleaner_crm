# WebSockAdapter.UpgradeValidation

Provides validation of WebSocket upgrade requests as described in RFC6455§4.2 & RFC8441§5

The `validate_upgrade/1` function is called internally by `WebSockAdapter.upgrade/4`; there is
no need to call it yourself before attempting an upgrade (though doing so is harmless)

## validate_upgrade/1

Validates that the request satisfies the requirements to issue a WebSocket upgrade response.

Validations are performed based on the clauses laid out in RFC6455§4.2 & RFC8441§5

This function does not actually perform an upgrade or change the connection in any way.
Regardless of whether or not this function indicates a satisfactory connection, the
underlying web server MAY still choose to not perform the upgrade (this scenario likely
indicates a discrepancy between the validations done here and those done in the underlying web
server & would merit further investigation)

Returns `:ok` if the connection satisfies the requirements for a WebSocket upgrade, and
`{:error, reason}` if not

## validate_upgrade!/1

Raising variant of `validate_upgrade/1`.

Returns `:ok` if the connection satisfies the requirements for a WebSocket upgrade, and raises
a `WebSockAdapter.UpgradeError` error if validation fails.