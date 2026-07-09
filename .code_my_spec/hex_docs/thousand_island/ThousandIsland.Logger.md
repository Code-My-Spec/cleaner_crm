# ThousandIsland.Logger

Logging conveniences for Thousand Island servers

Allows dynamically adding and altering the log level used to trace connections
within a Thousand Island server via the use of telemetry hooks. Should you wish
to do your own logging or tracking of these events, a complete list of the
telemetry events emitted by Thousand Island is described in the module
documentation for `ThousandIsland.Telemetry`.

## attach_logger/1

Start logging Thousand Island at the specified log level. Valid values for log
level are `:error`, `:info`, `:debug`, and `:trace`. Enabling a given log
level implicitly enables all higher log levels as well.

## detach_logger/1

Stop logging Thousand Island at the specified log level. Disabling a given log
level implicitly disables all lower log levels as well.