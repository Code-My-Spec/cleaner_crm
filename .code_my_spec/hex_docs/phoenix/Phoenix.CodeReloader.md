# Phoenix.CodeReloader

A plug and module to handle automatic code reloading.

To avoid race conditions, all code reloads are funneled through a
sequential call operation.

## reload/2

Reloads code for the current Mix project by invoking the
`:reloadable_compilers` on the list of `:reloadable_apps`.

This is configured in your application environment like:

    config :your_app, YourAppWeb.Endpoint,
      reloadable_compilers: [:gettext, :elixir],
      reloadable_apps: [:ui, :backend]

Keep in mind `:reloadable_compilers` must be a subset of the
`:compilers` specified in `project/0` in your `mix.exs`.

The `:reloadable_apps` defaults to `nil`. In such case
default behaviour is to reload the current project if it
consists of a single app, or all applications within an umbrella
project. You can set `:reloadable_apps` to a subset of default
applications to reload only some of them, an empty list - to
effectively disable the code reloader, or include external
applications from library dependencies.

This function is a no-op and returns `:ok` if Mix is not available.

The reloader should also be configured as a Mix listener in project's
mix.exs file (since Elixir v1.18):

    def project do
      [
        ...,
        listeners: [Phoenix.CodeReloader]
      ]
    end

This way the reloader can notice whenever the project is compiled
concurrently.

## Options

  * `:reloadable_args` - additional CLI args to pass to the compiler tasks.
    Defaults to `["--no-all-warnings"]` so only warnings related to the
    files being compiled are printed

## init/1

API used by Plug to start the code reloader.

## call/2

API used by Plug to invoke the code reloader on every request.