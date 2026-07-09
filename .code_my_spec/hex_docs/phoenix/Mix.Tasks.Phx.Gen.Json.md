# Mix.Tasks.Phx.Gen.Json

Generates controller, JSON view, and context for a JSON resource.

The format is:

```console
$ mix phx.gen.json [<context>] <schema> <table> <attr:type> [<attr:type>...]
```

For example:

```console
$ mix phx.gen.json User users name:string age:integer
```

Will generate a `User` schema for the `users` table within the `Users` context,
with the attributes `name` (as a string) and `age` (as an integer).

You can also explicitly pass the context name as argument, whenever the context
is well defined:

```console
$ mix phx.gen.json Accounts User users name:string age:integer
```

The first argument is the context module (`Accounts`) followed by
the schema module (`User`), table name (`users`), and attributes.

The context is an Elixir module that serves as an API boundary for
the given resource. A context often holds many related resources.
Therefore, if the context already exists, it will be augmented with
functions for the given resource.

The schema is responsible for mapping the database fields into an
Elixir struct. It is followed by a list of attributes with their
respective names and types. See `mix phx.gen.schema` for more
information on attributes.

Overall, this generator will add the following files to `lib/`:

  * a context module in `lib/app/accounts.ex` for the accounts API
  * a schema in `lib/app/accounts/user.ex`, with an `users` table
  * a controller in `lib/app_web/controllers/user_controller.ex`
  * a JSON view collocated with the controller in `lib/app_web/controllers/user_json.ex`

A migration file for the repository and test files for the context and
controller features will also be generated.

## API Prefix

By default, the prefix "/api" will be generated for API route paths.
This can be customized via the `:api_prefix` generators configuration:

    config :your_app, :generators,
      api_prefix: "/api/v1"

## Scopes

If your application configures its own default [scope](scopes.md), then this generator
will automatically make sure all of your context operations are correctly scoped.
You can pass the `--no-scope` flag to disable the scoping.

## Umbrella app configuration

By default, Phoenix injects both web and domain specific functionality into the same
application. When using umbrella applications, those concerns are typically broken
into two separate apps, your context application - let's call it `my_app` - and its web
layer, which Phoenix assumes to be `my_app_web`.

You can teach Phoenix to use this style via the `:context_app` configuration option
in your `my_app_umbrella/config/config.exs`:

    config :my_app_web,
      ecto_repos: [Stuff.Repo],
      generators: [context_app: :my_app]

Alternatively, the `--context-app` option may be supplied to the generator:

```console
$ mix phx.gen.html Accounts User users --context-app my_app
```

## Web namespace

By default, the controller and HTML views are not namespaced but you can add
a namespace by passing the `--web` flag with a module name, for example:

```console
$ mix phx.gen.json Accounts User users --web Accounts
```

Which would generate a `lib/app_web/controllers/accounts/user_controller.ex` and
`lib/app_web/controllers/accounts/user_json.ex`.

## Customizing the context, schema, tables and migrations

In some cases, you may wish to bootstrap JSON views, controllers,
and controller tests, but leave internal implementation of the context
or schema to yourself. You can use the `--no-context` and `--no-schema`
flags for file generation control. Note `--no-context` implies `--no-schema`:

```console
$ mix phx.gen.live Accounts User users --no-context name:string
```

In the cases above, tests are still generated, but they will all fail.

You can also change the table name or configure the migrations to
use binary ids for primary keys, see `mix phx.gen.schema` for more
information.