# Phoenix.Tracker



## track/5

Tracks a presence.

  * `tracker_name` - The registered name of the tracker server
  * `pid` - The Pid to track
  * `topic` - The `Phoenix.PubSub` topic for this presence
  * `key` - The key identifying this presence
  * `meta` - The map of metadata to attach to this presence

A process may be tracked multiple times, provided the topic and key pair
are unique for any prior calls for the given process.

## Examples

    iex> Phoenix.Tracker.track(MyTracker, self(), "lobby", u.id, %{stat: "away"})
    {:ok, "1WpAofWYIAA="}

    iex> Phoenix.Tracker.track(MyTracker, self(), "lobby", u.id, %{stat: "away"})
    {:error, {:already_tracked, #PID<0.56.0>, "lobby", "123"}}

## untrack/4

Untracks a presence.

  * `tracker_name` - The registered name of the tracker server
  * `pid` - The Pid to untrack
  * `topic` - The `Phoenix.PubSub` topic to untrack for this presence
  * `key` - The key identifying this presence

All presences for a given Pid can be untracked by calling the
`Phoenix.Tracker.untrack/2` signature of this function.

## Examples

    iex> Phoenix.Tracker.untrack(MyTracker, self(), "lobby", u.id)
    :ok
    iex> Phoenix.Tracker.untrack(MyTracker, self())
    :ok

## update/5

Updates a presence's metadata.

  * `tracker_name` - The registered name of the tracker server
  * `pid` - The Pid being tracked
  * `topic` - The `Phoenix.PubSub` topic to update for this presence
  * `key` - The key identifying this presence
  * `meta` - Either a new map of metadata to attach to this presence,
    or a function. The function will receive the current metadata as
    input and the return value will be used as the new metadata

## Examples

    iex> Phoenix.Tracker.update(MyTracker, self(), "lobby", u.id, %{stat: "zzz"})
    {:ok, "1WpAofWYIAA="}

    iex> Phoenix.Tracker.update(MyTracker, self(), "lobby", u.id, fn meta -> Map.put(meta, :away, true) end)
    {:ok, "1WpAofWYIAA="}

## list/2

Lists all presences tracked under a given topic.

  * `tracker_name` - The registered name of the tracker server
  * `topic` - The `Phoenix.PubSub` topic

Returns a list of presences in key/metadata tuple pairs.

## Examples

    iex> Phoenix.Tracker.list(MyTracker, "lobby")
    [{123, %{name: "user 123"}}, {456, %{name: "user 456"}}]

## get_by_key/3

Gets presences tracked under a given topic and key pair.

  * `tracker_name` - The registered name of the tracker server
  * `topic` - The `Phoenix.PubSub` topic
  * `key` - The key of the presence

Returns a list of presence metadata.

## Examples

    iex> Phoenix.Tracker.get_by_key(MyTracker, "lobby", "user1")
    [{#PID<0.88.0>, %{name: "User 1"}}, {#PID<0.89.0>, %{name: "User 1"}}]

## graceful_permdown/1

Gracefully shuts down by broadcasting permdown to all replicas.

## Examples

    iex> Phoenix.Tracker.graceful_permdown(MyTracker)
    :ok

## start_link/3

Starts a tracker pool.

  * `tracker` - The tracker module implementing the `Phoenix.Tracker` behaviour
  * `tracker_arg` - The argument to pass to the tracker handler `c:init/1`
  * `pool_opts` - The list of options used to construct the shard pool

## Required `pool_opts`:

  * `:name` - The name of the server, such as: `MyApp.Tracker`
    This will also form the common prefix for all shard names
  * `:pubsub_server` - The name of the PubSub server, such as: `MyApp.PubSub`

## Optional `pool_opts`:

  * `:broadcast_period` - The interval in milliseconds to send delta broadcasts
    across the cluster. Default `1500`
  * `:max_silent_periods` - The max integer of broadcast periods for which no
    delta broadcasts have been sent. Default `10` (15s heartbeat)
  * `:down_period` - The interval in milliseconds to flag a replica
    as temporarily down. Default `broadcast_period * max_silent_periods * 2`
    (30s down detection). Note: This must be at least 2x the `broadcast_period`.
  * `permdown_on_shutdown` - boolean; whether to immediately call
    `graceful_permdown/1` on the tracker during a graceful shutdown. See
    'Application Shutdown' section. You can only safely set this if `Phoenix.Tracker`
    is mounted at the root of your supervision tree and the strategy is `:one_for_one`.
    Default `false`.
  * `:permdown_period` - The interval in milliseconds to flag a replica
    as permanently down, and discard its state.
    Note: This must be at least greater than the `down_period`.
    Default `1_200_000` (20 minutes)
  * `:clock_sample_periods` - The numbers of heartbeat windows to sample
    remote clocks before collapsing and requesting transfer. Default `2`
  * `:max_delta_sizes` - The list of delta generation sizes to keep before
    falling back to sending entire state. Defaults `[100, 1000, 10_000]`.
  * `:log_level` - The log level to log events, defaults `:debug` and can be
    disabled with `false`
  * `:pool_size` - The number of tracker shards to launch. Default `1`