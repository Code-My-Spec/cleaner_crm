# Mix.Tasks.Phx.Routes

Prints all routes for the default or a given router.
Can also locate the controller function behind a specified url.

    $ mix phx.routes [ROUTER] [--info URL]

The default router is inflected from the application
name unless a configuration named `:namespace`
is set inside your application configuration. For example,
the configuration:

    config :my_app,
      namespace: My.App

will exhibit the routes for `My.App.Router` when this
task is invoked without arguments.

Umbrella projects do not have a default router and
therefore always expect a router to be given. An
alias can be added to mix.exs to automate this:

    defp aliases do
      [
        "phx.routes": "phx.routes MyAppWeb.Router",
        # aliases...
      ]

## Options

  * `--info` - locate the controller function definition called by the given url
  * `--method` - what HTTP method to use with the given url, only works when used with `--info` and defaults to `get`

## Examples

Print all routes for the default router:

    $ mix phx.routes

Print all routes for the given router:

    $ mix phx.routes MyApp.AnotherRouter

Print information about the controller function called by a specified url:

    $ mix phx.routes --info http://0.0.0.0:4000/home
      Module: RouteInfoTestWeb.PageController
      Function: :index
      /home/my_app/controllers/page_controller.ex:4

Print information about the controller function called by a specified url and HTTP method:

    $ mix phx.routes --info http://0.0.0.0:4000/users --method post
      Module: RouteInfoTestWeb.UserController
      Function: :create
      /home/my_app/controllers/user_controller.ex:24