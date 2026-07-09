# Phoenix.Tracker.Clock



## clockset_replicas/1

Returns a list of replicas from a list of contexts.

## append_clock/2

Adds a replicas context to a clockset, keeping only dominate contexts.

## dominates?/2

Checks if one clock causally dominates the other for all replicas.

## dominates_or_equal?/2

Checks if one clock causally dominates the other for their shared replicas.

## upperbound/2

Returns the upper bound causal context of two clocks.

## lowerbound/2

Returns the lower bound causal context of two clocks.

## filter_replicas/2

Returns the clock with just provided replicas.

## replicas/1

Returns replicas from the given clock.