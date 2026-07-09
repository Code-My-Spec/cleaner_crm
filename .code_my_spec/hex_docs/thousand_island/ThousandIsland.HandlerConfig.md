# ThousandIsland.HandlerConfig

A minimal config struct containing only the fields needed by connection handlers.

This is used internally by `ThousandIsland.Handler`

## from_server_config/1

Creates a HandlerConfig from a ServerConfig, extracting only the fields needed
by connection handlers. This should be called once per acceptor at initialization.