# Finch.Pool

Defines a pool structure for identifying and configuring connection pools.

A pool is identified by its `scheme`, `host`, `port` and `tag`.
You can create pool structs using `new/2`.

## Examples

    # Create a pool from a URL
    pool = Finch.Pool.new("https://api.example.com")

    # Create a tagged pool from a URL
    pool = Finch.Pool.new("https://api.example.com", tag: :api)

    # Create a pool for a Unix socket
    pool = Finch.Pool.new("http+unix:///tmp/socket")

    # Create a tagged pool for a Unix socket
    pool = Finch.Pool.new("http+unix:///tmp/socket", tag: :api)

## User-managed pools

Use `child_spec/1` to start pools under your own supervision tree. The Finch
instance must be started before the pool. See `child_spec/1` for options and examples.

## new/2

Creates a new pool struct from a URL.

Supports `http://`, `https://`, `http+unix://`, and `https+unix://` schemes.

The second argument is an optional keyword list with:
- `:tag` - The tag for the pool (defaults to `:default`)

## Examples

    # From URL
    pool = Finch.Pool.new("https://api.example.com")

    # Unix socket pool using URL
    pool = Finch.Pool.new("http+unix:///tmp/socket")

    # Tagged pool
    pool = Finch.Pool.new("http+unix:///tmp/socket", tag: :api)

## child_spec/1

Returns a child specification for starting a pool under your own supervision tree.

This allows you to manage the lifecycle of pools independently from Finch's
internal DynamicSupervisor. The pools integrate fully with Finch's APIs.

## Options

  * `:finch` - Required. The name of your Finch instance.
  * `:pool` - Required. A `Finch.Pool.t()` struct identifying the pool.
  * All pool configuration options from `Finch.start_link/1` are supported:
    `:size`, `:count`, `:protocols`, `:conn_opts`, etc.

## Example

    children = [
      {Finch, name: MyFinch},
      {Finch.Pool, finch: MyFinch, pool: Finch.Pool.new("https://api.internal", tag: :api), size: 10}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)

## Notes

  * The Finch instance must be started before the user-managed pool
  * `Finch.stop_pool/2` works on user-managed pools
  * `Finch.get_pool_status/2` works if `start_pool_metrics?: true`