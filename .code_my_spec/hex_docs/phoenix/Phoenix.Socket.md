# Phoenix.Socket



## __using__/1

Shortcut version of `connect/3` which does not receive `connect_info`.

Provided for backwards compatibility.

## assign/3

Adds a `key`/`value` pair to `socket` assigns.

See also `assign/2` to add multiple key/value pairs.

## Examples

    iex> assign(socket, :name, "Elixir")

## assign/2

Adds key/value pairs to socket assigns.
Accepts a keyword list, a map, or a single-argument function.

When a keyword list or map is provided, it will be merged into the existing assigns.

If a function is given, it takes the current assigns as an argument and its return
value will be merged into the current assigns.

## Examples

    iex> assign(socket, name: "Elixir", logo: "💧")
    iex> assign(socket, %{name: "Elixir"})
    iex> assign(socket, fn %{name: name, logo: logo} -> %{title: Enum.join([name, logo], " | ")} end)

## channel/3

Defines a channel matching the given topic and transports.

  * `topic_pattern` - The string pattern, for example `"room:*"`, `"users:*"`,
    or `"system"`
  * `module` - The channel module handler, for example `MyAppWeb.RoomChannel`
  * `opts` - The optional list of options, see below

## Options

  * `:assigns` - the map of socket assigns to merge into the socket on join

## Examples

    channel "topic1:*", MyChannel

## Topic Patterns

The `channel` macro accepts topic patterns in two flavors. A splat (the `*`
character) argument can be provided as the last character to indicate a
`"topic:subtopic"` match. If a plain string is provided, only that topic will
match the channel handler. Most use-cases will use the `"topic:*"` pattern to
allow more versatile topic scoping.

See `Phoenix.Channel` for more information