# Phoenix.Socket.Reply

Defines a reply sent from channels to transports.

The message format requires the following keys:

  * `:topic` - The string topic or topic:subtopic pair namespace, for example "messages", "messages:123"
  * `:status` - The reply status as an atom
  * `:payload` - The reply payload
  * `:ref` - The unique string ref
  * `:join_ref` - The unique string ref when joining