# ThousandIsland.Transport

This module describes the behaviour required for Thousand Island to interact
with low-level sockets. It is largely internal to Thousand Island, however users
are free to implement their own versions of this behaviour backed by whatever
underlying transport they choose. Such a module can be used in Thousand Island
by passing its name as the `transport_module` option when starting up a server,
as described in `ThousandIsland`.