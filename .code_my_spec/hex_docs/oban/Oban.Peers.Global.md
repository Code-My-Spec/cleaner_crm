# Oban.Peers.Global

A cluster based peer that coordinates through a distributed registry.

Leadership is coordinated through global locks. It requires a functional distributed Erlang
cluster, without one global plugins (Cron, Lifeline, etc.) will not function correctly.

## Usage

Specify the `Global` peer in your Oban configuration.

    config :my_app, Oban,
      peer: Oban.Peers.Global,
      ...