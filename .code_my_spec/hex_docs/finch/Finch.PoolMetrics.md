# Finch.PoolMetrics



## table_name/1

Returns the ETS table name for a Finch instance.

## new/1

Creates the ETS table for a Finch instance. Called once during Finch.init/1.

## insert/4

Inserts a full metrics row for a pool worker.
`row` is a tuple like `{{pool_name, pool_idx}, val1, val2, ...}`.

## update/5

Atomically increments the value at `position` by `delta`.
Position 2 is the first metric value (position 1 is the key).

## put/5

Sets the value at `position` to an absolute value.

## get_all_rows/2

Returns all metrics rows for the given pool_name, using ordered_set prefix lookup.

## delete/3

Deletes the metrics row for a given pool worker.
Accepts the ETS table name directly.

## delete_pool/2

Deletes all metrics rows for all workers of a given pool.