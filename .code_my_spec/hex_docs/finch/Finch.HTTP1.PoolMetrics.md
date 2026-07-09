# Finch.HTTP1.PoolMetrics

HTTP1 Pool metrics.

Available metrics:

  * `:pid` - The pid of the pool worker process
  * `:pool_index` - Index of the pool
  * `:pool_size` - Total number of connections of the pool
  * `:available_connections` - Number of available connections
  * `:in_use_connections` - Number of connections currently in use

Caveats:

  * A given number X of `available_connections` does not mean that currently
  exists X connections to the server sitting on the pool. Because Finch uses
  a lazy strategy for workers initialization, every pool starts with it's
  size as available connections even if they are not started yet. In practice
  this means that `available_connections` may be connections sitting on the pool
  or available space on the pool for a new one if required.