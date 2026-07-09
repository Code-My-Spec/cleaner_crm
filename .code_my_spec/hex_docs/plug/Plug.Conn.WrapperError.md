# Plug.Conn.WrapperError

Wraps the connection in an error which is meant
to be handled upper in the stack.

Used by both `Plug.Debugger` and `Plug.ErrorHandler`.

## reraise/1

Reraises an error or a wrapped one.