# Phoenix.Presence

Provides Presence tracking to processes and channels.

This behaviour provides presence features such as fetching
presences for a given topic, as well as handling diffs of
join and leave events as they occur in real-time. Using this
module defines a supervisor and a module that implements the
`Phoenix.Tracker` behaviour that uses `Phoenix.PubSub` to
broadcast presence updates.

In case you want to use only a subset of the functionality
provided by `Phoenix.Presence`, such as tracking processes
but without broadcasting updates, we recommend that you look
at the `Phoenix.Tracker` functionality from the `phoenix_pubsub`
project.

## Example Usage

Start by defining a presence module within your application
which uses `Phoenix.Presence` and provide the `:otp_app` which
holds your configuration, as well as the `:pubsub_server`.

    defmodule MyAppWeb.Presence do
      use Phoenix.Presence,
        otp_app: :my_app,
        pubsub_server: MyApp.PubSub
    end

The `:pubsub_server` must point to an existing pubsub server
running in your application, which is included by default as
`MyApp.PubSub` for new applications.

Next, add the new supervisor to your supervision tree in
`lib/my_app/application.ex`. It must be after the PubSub child
and before the endpoint:

    children = [
      ...
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyAppWeb.Presence,
      MyAppWeb.Endpoint
    ]

Once added, presences can be tracked in your channel after joining:

    defmodule MyAppWeb.MyChannel do
      use MyAppWeb, :channel
      alias MyAppWeb.Presence

      def join("some:topic", _params, socket) do
        send(self(), :after_join)
        {:ok, assign(socket, :user_id, ...)}
      end

      def handle_info(:after_join, socket) do
        {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
          online_at: inspect(System.system_time(:second))
        })

        push(socket, "presence_state", Presence.list(socket))
        {:noreply, socket}
      end
    end

In the example above, `Presence.track` is used to register this channel's process as a
presence for the socket's user ID, with a map of metadata.
Next, the current presence information for
the socket's topic is pushed to the client as a `"presence_state"` event.

Finally, a diff of presence join and leave events will be sent to the
client as they happen in real-time with the "presence_diff" event.
The diff structure will be a map of `:joins` and `:leaves` of the form:

    %{
      joins: %{"123" => %{metas: [%{status: "away", phx_ref: ...}]}},
      leaves: %{"456" => %{metas: [%{status: "online", phx_ref: ...}]}}
    },

See `c:list/1` for more information on the presence data structure.

## Custom dispatcher

It's possible to customize the dispatcher module used to broadcast.
By default, `Phoenix.Channel.Server` is used, which is the same dispatcher
used by channels. To customize the dispatcher, pass the `:dispatcher` option
when using `Phoenix.Presence`:

    use Phoenix.Presence,
      otp_app: :my_app,
      pubsub_server: MyApp.PubSub,
      dispatcher: MyApp.CustomDispatcher

See `m:Phoenix.PubSub#module-custom-dispatching` for more information on
custom dispatchers.

## Fetching Presence Information

Presence metadata should be minimized and used to store small,
ephemeral state, such as a user's "online" or "away" status.
More detailed information, such as user details that need to be fetched
from the database, can be achieved by overriding the `c:fetch/2` function.

The `c:fetch/2` callback is triggered when using `c:list/1` and on
every update, and it serves as a mechanism to fetch presence information
a single time, before broadcasting the information to all channel subscribers.
This prevents N query problems and gives you a single place to group
isolated data fetching to extend presence metadata.

The function must return a map of data matching the outlined Presence
data structure, including the `:metas` key, but can extend the map of
information to include any additional information. For example:

    def fetch(_topic, presences) do
      users = presences |> Map.keys() |> Accounts.get_users_map()

      for {key, %{metas: metas}} <- presences, into: %{} do
        {key, %{metas: metas, user: users[String.to_integer(key)]}}
      end
    end

Where `Account.get_users_map/1` could be implemented like:

    def get_users_map(ids) do
      query =
        from u in User,
          where: u.id in ^ids,
          select: {u.id, u}

      query |> Repo.all() |> Enum.into(%{})
    end

The `fetch/2` function above fetches all users from the database who
have registered presences for the given topic. The presences
information is then extended with a `:user` key of the user's
information, while maintaining the required `:metas` field from the
original presence data.

## Using Elixir as a Presence Client

Presence is great for external clients, such as JavaScript applications, but
it can also be used from an Elixir client process to keep track of presence
changes as they happen on the server. This can be accomplished by implementing
the optional [`init/1`](`c:init/1`) and [`handle_metas/4`](`c:handle_metas/4`)
callbacks on your presence module. For example, the following callback
receives presence metadata changes, and broadcasts to other Elixir processes
about users joining and leaving:

    defmodule MyApp.Presence do
      use Phoenix.Presence,
        otp_app: :my_app,
        pubsub_server: MyApp.PubSub

      def init(_opts) do
        {:ok, %{}} # user-land state
      end

      def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
        # fetch existing presence information for the joined users and broadcast the
        # event to all subscribers
        for {user_id, presence} <- joins do
          user_data = %{user: presence.user, metas: Map.fetch!(presences, user_id)}
          msg = {MyApp.PresenceClient, {:join, user_data}}
          Phoenix.PubSub.local_broadcast(MyApp.PubSub, topic, msg)
        end

        # fetch existing presence information for the left users and broadcast the
        # event to all subscribers
        for {user_id, presence} <- leaves do
          metas =
            case Map.fetch(presences, user_id) do
              {:ok, presence_metas} -> presence_metas
              :error -> []
            end

          user_data = %{user: presence.user, metas: metas}
          msg = {MyApp.PresenceClient, {:leave, user_data}}
          Phoenix.PubSub.local_broadcast(MyApp.PubSub, topic, msg)
        end

        {:ok, state}
      end
    end

The `handle_metas/4` callback receives the topic, presence diff, current presences
for the topic with their metadata, and any user-land state accumulated from init and
subsequent `handle_metas/4` calls. In our example implementation, we walk the `:joins` and
`:leaves` in the diff, and populate a complete presence from our known presence information.
Then we broadcast to the local node subscribers about user joins and leaves.

## Testing with Presence

Every time the `fetch` callback is invoked, it is done from a separate
process. Given those processes run asynchronously, it is often necessary
to guarantee they have been shutdown at the end of every test. This can
be done by using ExUnit's `on_exit` hook plus `fetchers_pids` function:

    on_exit(fn ->
      for pid <- MyAppWeb.Presence.fetchers_pids() do
        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, _, _, _}, 1000
      end
    end)

## __using__/1

Receives presence metadata changes.