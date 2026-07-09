# DBConnection.TelemetryListener

A connection listener that emits telemetry events for connection and disconnection

It monitors connection processes and ensures that disconnection events are
always emitted.

## Usage

Start the listener, and pass it under the `:connection_listeners` option when
starting DBConnection:

    {:ok, pid} = DBConnection.TelemetryListener.start_link()
    {:ok, _conn} = DBConnection.start_link(SomeModule, connection_listeners: [pid])

    # Using a tag, which will be sent in telemetry metadata
    {:ok, _conn} = DBConnection.start_link(SomeModule, connection_listeners: {[pid], :my_tag})

    # Or, with a Supervisor:
    Supervisor.start_link([
      {DBConnection.TelemetryListener, name: MyListener},
      DBConnection.child_spec(SomeModule, connection_listeners: {[MyListener], :my_tag})
    ])

When using with Ecto, you can pass the `connection_listeners` option to Ecto, and we
recommend passing the repository as the tag. In your supervision tree:

    Supervisor.start_link([
      {DBConnection.TelemetryListener, name: MyApp.DBListener},
      {MyApp.Repo, connection_listeners: {[MyApp.DBListener], MyApp.Repo})
    ])

## Telemetry events

### Connected

`[:db_connection, :connected]` - Executed after a connection is established.

#### Measurements

  * `:count` - Always 1

#### Metadata

  * `:pid` - The connection pid
  * `:tag` - The connection pool tag

### Disconnected

`[:db_connection, :disconnected]` - Executed after a disconnect.

#### Measurements

  * `:count` - Always 1

#### Metadata

  * `:pid` - The connection pid
  * `:tag` - The connection pool tag

## start_link/1

Starts a telemetry listener