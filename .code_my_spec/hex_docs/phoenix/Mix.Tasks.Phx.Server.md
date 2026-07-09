# Mix.Tasks.Phx.Server

Starts the application by configuring all endpoints servers to run.

Note: to start the endpoint without using this mix task you must set
`server: true` in your `Phoenix.Endpoint` configuration.

## Command line options

  * `--open` - open browser window for each started endpoint

Furthermore, this task accepts the same command-line options as
`mix run`.

For example, to run `phx.server` without recompiling:

    $ mix phx.server --no-compile

The `--no-halt` flag is automatically added.

Note that the `--no-deps-check` flag cannot be used this way,
because Mix needs to check dependencies to find `phx.server`.

To run `phx.server` without checking dependencies, you can run:

    $ mix do deps.loadpaths --no-deps-check, phx.server