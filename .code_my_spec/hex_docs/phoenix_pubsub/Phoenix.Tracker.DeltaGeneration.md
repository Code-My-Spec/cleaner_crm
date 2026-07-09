# Phoenix.Tracker.DeltaGeneration



## extract/4

Extracts minimal delta from generations to satisfy remote clock.

Falls back to extracting entire crdt if unable to match delta.

## remove_down_replicas/2

Prunes permanently downed replicates from the delta generation list