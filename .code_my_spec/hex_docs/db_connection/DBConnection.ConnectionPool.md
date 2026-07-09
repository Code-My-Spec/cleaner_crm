# DBConnection.ConnectionPool

The default connection pool.

The queueing algorithm is based on [CoDel](https://queue.acm.org/appendices/codel.html).

You're not supposed to call any functions on this pool directly, but only pass this
as the value of the `:pool` option in functions such as `DBConnection.start_link/2`.