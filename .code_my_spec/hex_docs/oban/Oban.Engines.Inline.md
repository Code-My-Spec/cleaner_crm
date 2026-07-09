# Oban.Engines.Inline

A testing-specific engine that's used when Oban is started with `testing: :inline`.

## Usage

This is meant for testing and shouldn't be configured directly:

    Oban.start_link(repo: MyApp.Repo, testing: :inline)