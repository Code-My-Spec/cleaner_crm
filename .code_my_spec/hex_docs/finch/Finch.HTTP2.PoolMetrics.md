# Finch.HTTP2.PoolMetrics

HTTP2 Pool metrics.

Available metrics:

  * `:pid` - The pid of the pool worker process
  * `:pool_index` - Index of the pool
  * `:in_flight_requests` - Number of requests currently on the connection
  * `:available_connections` - Number of available connections
  * `:max_concurrent_streams` - The server's max concurrent streams setting.
    This is 0 until the server's SETTINGS frame has been received.

Caveats:

  * HTTP2 pools have only one connection and leverage the multiplex nature
  of the protocol. That's why we only keep the in flight requests, representing
  the number of streams currently running on the connection.