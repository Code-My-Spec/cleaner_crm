# Phoenix.Socket.Message

Defines a message dispatched over transport to channels and vice-versa.

The message format requires the following keys:

  * `:topic` - The string topic or topic:subtopic pair namespace, for
    example "messages", "messages:123"
  * `:event`- The string event name, for example "phx_join"
  * `:payload` - The message payload
  * `:ref` - The unique string ref
  * `:join_ref` - The unique string ref when joining

## from_map!/1

Converts a map with string keys into a message struct.

Raises `Phoenix.Socket.InvalidMessageError` if not valid.