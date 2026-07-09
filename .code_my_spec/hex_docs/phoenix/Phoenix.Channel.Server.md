# Phoenix.Channel.Server



## join/4

Joins the channel in socket with authentication payload.

## socket/1

Gets the socket from the channel.

Used by channel tests.

## close/2

Emulates the socket being closed.

Used by channel tests.

## dispatch/3

Hook invoked by Phoenix.PubSub dispatch.

## broadcast/4

Broadcasts on the given pubsub server with the given
`topic`, `event` and `payload`.

The message is encoded as `Phoenix.Socket.Broadcast`.

## broadcast!/4

Broadcasts on the given pubsub server with the given
`topic`, `event` and `payload`.

Raises in case of crashes.

## broadcast_from/5

Broadcasts on the given pubsub server with the given
`from`, `topic`, `event` and `payload`.

The message is encoded as `Phoenix.Socket.Broadcast`.

## broadcast_from!/5

Broadcasts on the given pubsub server with the given
`from`, `topic`, `event` and `payload`.

Raises in case of crashes.

## local_broadcast/4

Broadcasts on the given pubsub server with the given
`topic`, `event` and `payload`.

The message is encoded as `Phoenix.Socket.Broadcast`.

## local_broadcast_from/5

Broadcasts on the given pubsub server with the given
`from`, `topic`, `event` and `payload`.

The message is encoded as `Phoenix.Socket.Broadcast`.

## push/6

Pushes a message with the given topic, event and payload
to the given process.

Payloads are serialized before sending with the configured serializer.

## reply/6

Replies to a given ref to the transport process.

Payloads are serialized before sending with the configured serializer.