# Oban.Peers.Database

A peer that coordinates centrally through a database table.

Database peers don't require clustering through distributed Erlang or any other
interconnectivity between nodes. Leadership is coordinated through the `oban_peers` table in
your database. With a standard Oban config the `oban_peers` table will only have one row, and
that node is the leader.

Applications that run multiple Oban instances will have one row per instance. For example, an
umbrella application that runs `Oban.A` and `Oban.B` will have two rows in `oban_peers`.

## Usage

This is the default peer for the `Basic` and `Dolphin` engines and no configuration is
necessary. However, to be explicit, specify the `Database` peer in your configuration.

    config :my_app, Oban,
      peer: Oban.Peers.Database,
      ...