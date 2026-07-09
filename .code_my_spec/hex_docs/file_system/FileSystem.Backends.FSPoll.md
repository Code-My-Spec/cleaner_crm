# FileSystem.Backends.FSPoll

File system backend for any OS.

## Backend Options

  * `:interval` (integer, default: 1000), polling interval

## Using FSPoll Backend

Unlike other backends, polling backend is never automatically chosen in any
OS environment, despite being usable on all platforms.

To use polling backend, one has to explicitly specify in the backend option.