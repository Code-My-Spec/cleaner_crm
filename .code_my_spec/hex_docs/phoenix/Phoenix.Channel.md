# Phoenix.Channel



## __using__/1

Invoked when the channel process is about to exit.

See `c:GenServer.terminate/2`.

## intercept/1

Defines which Channel events to intercept for `handle_out/3` callbacks.

By default, broadcasted events are pushed directly to the client, but
intercepting events gives your channel a chance to customize the event
for the client to append extra information or filter the message from being
delivered.

*Note*: intercepting events can introduce significantly more overhead if a
large number of subscribers must customize a message since the broadcast will
be encoded N times instead of a single shared encoding across all subscribers.

## Examples

    intercept ["new_msg"]

    def handle_out("new_msg", payload, socket) do
      push(socket, "new_msg", Map.merge(payload,
        is_editable: User.can_edit_message?(socket.assigns[:user], payload)
      ))
      {:noreply, socket}
    end

`handle_out/3` callbacks must return one of:

    {:noreply, Socket.t} |
    {:noreply, Socket.t, timeout | :hibernate} |
    {:stop, reason :: term, Socket.t}

## broadcast/3

Broadcast an event to all subscribers of the socket topic.

The event's message must be a serializable map or a tagged `{:binary, data}`
tuple where `data` is binary data.

## Examples

    iex> broadcast(socket, "new_message", %{id: 1, content: "hello"})
    :ok

    iex> broadcast(socket, "new_message", {:binary, "hello"})
    :ok

## broadcast!/3

Same as `broadcast/3`, but raises if broadcast fails.

## broadcast_from/3

Broadcast event from pid to all subscribers of the socket topic.

The channel that owns the socket will not receive the published
message. The event's message must be a serializable map or a tagged
`{:binary, data}` tuple where `data` is binary data.

## Examples

    iex> broadcast_from(socket, "new_message", %{id: 1, content: "hello"})
    :ok

    iex> broadcast_from(socket, "new_message", {:binary, "hello"})
    :ok

## broadcast_from!/3

Same as `broadcast_from/3`, but raises if broadcast fails.

## push/3

Sends an event directly to the connected client without requiring a prior
message from the client.

The event's message must be a serializable map or a tagged `{:binary, data}`
tuple where `data` is binary data.

Note that unlike some in client libraries, this server-side `push/3` does not
return a reference. If you need to get a reply from the client and to
correlate that reply with the message you pushed, you'll need to include a
unique identifier in the message, track it in the Channel's state, have the
client include it in its reply, and examine the ref when the reply comes to
`handle_in/3`.

## Examples

    iex> push(socket, "new_message", %{id: 1, content: "hello"})
    :ok

    iex> push(socket, "new_message", {:binary, "hello"})
    :ok

## reply/2

Replies asynchronously to a socket push.

The usual way of replying to a client's message is to return a tuple from `handle_in/3`
like:

    {:reply, {status, payload}, socket}

But sometimes you need to reply to a push asynchronously - that is, after
your `handle_in/3` callback completes. For example, you might need to perform
work in another process and reply when it's finished.

You can do this by generating a reference to the socket with `socket_ref/1`
and calling `reply/2` with that ref when you're ready to reply.

*Note*: A `socket_ref` is required so the `socket` itself is not leaked
outside the channel. The `socket` holds information such as assigns and
transport configuration, so it's important to not copy this information
outside of the channel that owns it.

Technically, `reply/2` will allow you to reply multiple times to the same
client message, and each reply will include the client message `ref`. But the
client may expect only one reply; in that case, `push/3` would be preferable
for the additional messages.

Payloads are serialized before sending with the configured serializer.

## Examples

    def handle_in("work", payload, socket) do
      Worker.perform(payload, socket_ref(socket))
      {:noreply, socket}
    end

    def handle_info({:work_complete, result, ref}, socket) do
      reply(ref, {:ok, result})
      {:noreply, socket}
    end

## socket_ref/1

Generates a `socket_ref` for an async reply.

See `reply/2` for example usage.