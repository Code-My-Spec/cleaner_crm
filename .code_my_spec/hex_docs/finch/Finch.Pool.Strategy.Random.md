# Finch.Pool.Strategy.Random

Selects a pool worker uniformly at random. No state required.

This is the default when no `pool_strategy` option is given, it is the fastest one to select
a worker, which is ideal if your workers will perform many short tasks.