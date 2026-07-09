# Phoenix.Socket.Broadcast

Defines a message sent from pubsub to channels and vice-versa.

The message format requires the following keys:

  * `:topic` - The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
  * `:event`- The string event name, for example "phx_join"
  * `:payload` - The message payload