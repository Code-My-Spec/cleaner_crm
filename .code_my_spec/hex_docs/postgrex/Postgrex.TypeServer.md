# Postgrex.TypeServer



## start_link/1

Starts a type server.

## fetch/1

Fetches a lock for the given type server.

We attempt to achieve a lock on the type server for updating the entries.
If another process got the lock we wait for it to finish.

## update/3

Update the type server using the given reference and configuration.

## done/2

Unlocks the given reference for a given module if no update.