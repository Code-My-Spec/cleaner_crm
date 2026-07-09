# Boundary.Mix.CompilerState



## references/0

Returns a lazy stream where each element is of type `t:Boundary.ref()`

## add_module_meta/3

Stores module meta.

The data is stored in memory, and later flushed to the manifest file.

## boundary_defs/1

Returns an enumerable stream of cached raw boundary definitions

If no cache exists, `nil` is returned.

## protocol_impls/1

Returns a mapset with all protocol implementation modules (define with `defimpl`) in the given app.

If no cache exists, `nil` is returned.