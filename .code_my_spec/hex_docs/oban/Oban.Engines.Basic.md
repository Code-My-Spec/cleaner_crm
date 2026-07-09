# Oban.Engines.Basic

The default engine for use with Postgres databases.

## Usage

This is the default engine, no additional configuration is necessary:

    Oban.start_link(repo: MyApp.Repo, queues: [default: 10])