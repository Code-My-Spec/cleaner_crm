# Phoenix.Tracker.State



## new/2

Creates a new set for the replica.

## Examples

    iex> Phoenix.Tracker.State.new(:replica1, :shard_name)
    %Phoenix.Tracker.State{...}

## clocks/1

Returns the causal context for the set.

## join/5

Adds a new element to the set.

## leave_join/5

Updates an element via leave and join.

Atomically updates ETS local entry.

## leave/4

Removes an element from the set.

## leave/2

Removes all elements from the set for the given pid.

## online_list/1

Returns a list of elements in the set belonging to an online replica.

## get_by_topic/2

Returns a list of elements for the topic who belong to an online replica.

## get_by_key/3

Returns a list of elements for the topic who belong to an online replica.

## tracked_values/3

Performs table lookup for tracked elements in the topic.

Filters out those present on downed replicas.

## tracked_key/4

Performs table lookup for tracked key in the topic.

Filters out those present on downed replicas.

## get_by_pid/4

Returns the element matching the pid, topic, and key.

## get_by_pid/2

Returns all elements for the pid.

## has_delta?/1

Checks if set has a non-empty delta.

## reset_delta/1

Resets the set's delta.

## extract/3

Extracts the set's elements from ets into a mergeable list.

Used when merging two sets.

## merge/2

Merges two sets, or a delta into a set.

Returns a 3-tuple of the updated set, and the joined and left elements.

## Examples

    iex> {s1, joined, left} =
         Phoenix.Tracker.State.merge(s1, Phoenix.Tracker.State.extract(s2))

    {%Phoenix.Tracker.State{}, [...], [...]}

## replica_up/2

Marks a replica as up in the set and returns rejoined users.

## replica_down/2

Marks a replica as down in the set and returns left users.

## remove_down_replicas/2

Removes all elements for replicas that are permanently gone.

## delta_size/1

Returns the dize of the delta.

## compact/1

Compacts a sets causal history.

Called as needed and after merges.