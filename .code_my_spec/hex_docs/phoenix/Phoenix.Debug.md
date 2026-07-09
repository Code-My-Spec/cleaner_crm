# Phoenix.Debug

Functions for runtime introspection and debugging of Phoenix applications.

This module provides utilities for inspecting and debugging Phoenix applications.
At the moment, it only includes functions related to `Phoenix.Socket` and `Phoenix.Channel`
processes.

It allows you to:

  * List all currently connected `Phoenix.Socket` transport processes.
  * List all channels for a given `Phoenix.Socket` process.
  * Get the socket of a channel process.
  * Check if a process is a `Phoenix.Socket` or `Phoenix.Channel`.

## list_sockets/0

Returns a list of all currently connected `Phoenix.Socket` transport processes.

Note that custom sockets implementing the `Phoenix.Socket.Transport` behaviour
are not listed.

Each process corresponds to one connection that can have multiple channels.

For example, when using Phoenix LiveView, the browser establishes a socket
connection when initially navigating to the page, and each live navigation
retains the same socket connection. Nested LiveViews also share the same
connection, each being a different channel. See `Phoenix.Debug.channels/1`.

## Examples

    iex> Phoenix.Debug.list_sockets()
    [%{pid: #PID<0.123.0>, module: Phoenix.LiveView.Socket, id: nil}]

## socket_process?/1

Returns true if the given pid is a `Phoenix.Socket` transport process.

It returns `false` for custom sockets implementing the `Phoenix.Socket.Transport` behaviour.

## Examples

    iex> Phoenix.Debug.list_sockets() |> Enum.at(0) |> Map.fetch!(:pid) |> socket_process?()
    true

    iex> socket_process?(pid(0,456,0))
    false

## channel_process?/1

Checks if the given pid is a `Phoenix.Channel` process.

> ### Custom channels {: .info}
> This function always returns `false` for [custom channels](`m:Phoenix.Socket#module-custom-channels`).

## list_channels/1

Returns a list of all currently connected channels for the given `Phoenix.Socket` pid.

Each channel is represented as a map with the following keys:

  - `:pid` - the pid of the channel process
  - `:status` - the status of the channel
  - `:topic` - the topic of the channel

> ### Custom channels {: .info}
> Note that the list also contains [custom channels](`m:Phoenix.Socket#module-custom-channels`)
> like LiveViews. You can check if a channel is a custom channel by using the
> `channel_process?/1` function, which returns `false` for custom channels.

## Examples

    iex> pid = Phoenix.Debug.list_sockets() |> Enum.at(0) |> Map.fetch!(:pid)
    iex> Phoenix.Debug.list_channels(pid)
    {:ok,
     [
       %{pid: #PID<0.1702.0>, status: :joined, topic: "lv:phx-GDp9a9UZPiTxcgnE"},
       %{pid: #PID<0.1727.0>, status: :joined, topic: "lv:sidebar"}
     ]}

    iex> Phoenix.Debug.list_channels(pid(0,456,0))
    {:error, :not_alive}

## socket/1

Returns the socket of the channel process.

Note: this only works for channels defined with `use Phoenix.Channel`.
For LiveViews, use the functions defined in `Phoenix.LiveView.Debug` instead.

## Examples

    iex> pid = Phoenix.Debug.list_sockets() |> Enum.at(0) |> Map.fetch!(:pid)
    iex> {:ok, channels} = Phoenix.Debug.list_channels(pid)
    iex> channels |> Enum.at(0) |> Map.fetch!(:pid) |> socket()
    {:ok, %Phoenix.Socket{...}}

    iex> socket(pid(0,456,0))
    {:error, :not_alive_or_not_a_channel}