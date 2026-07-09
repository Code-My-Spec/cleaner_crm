# Plug.Conn.Unfetched

A struct used as default on unfetched fields.

The `:aspect` key of the struct specifies what field is still unfetched.

## Examples

    unfetched = %Plug.Conn.Unfetched{aspect: :cookies}