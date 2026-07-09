# Finch.Request

A request struct.

## put_private/3

Sets a new **private** key and value in the request metadata. This storage is meant to be used by libraries
and frameworks to inject information about the request that needs to be retrieved later on, for example,
from handlers that consume `Finch.Telemetry` events.