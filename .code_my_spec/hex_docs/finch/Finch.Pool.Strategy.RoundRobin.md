# Finch.Pool.Strategy.RoundRobin

Selects pool workers in round-robin order using an atomics counter.

This ensures an evenly distribution of tasks.

It is recommended to share the same counter state across all usages of the same pool for proper
round-robin. Client processes can be passed a reference to such counter or it can be stored in a
`:persistent_term`.

## Example

    counter = Finch.Pool.Strategy.RoundRobin.new()
    Finch.request(req, MyFinch, pool_strategy: {Finch.Pool.Strategy.RoundRobin, counter})