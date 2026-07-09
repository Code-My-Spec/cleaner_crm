# Oban.Engines.Lite

An engine for running Oban with SQLite3.

## Usage

Start an `Oban` instance using the `Lite` engine:

    Oban.start_link(
      engine: Oban.Engines.Lite,
      queues: [default: 10],
      repo: MyApp.Repo
    )