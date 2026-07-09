# Mix.Tasks.Phx.Gen.Html

Generates controller with view, templates, schema and context for an HTML resource.

The format is:

```console
$ mix phx.gen.html [<context>] <schema> <table> <attr:type> [<attr:type>...]
```

For example:

```console
$ mix phx.gen.html User users name:string age:integer
```

Will generate a `User` schema for the `users` table within the `Users` context,
with the attributes `name` (as a string) and `age` (as an integer).

You can also explicitly pass the context name as argument, whenever the context
is well defined:

```console
$ mix phx.gen.html Accounts User users name:string age:integer
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

  * a controller in `lib/my_app_web/controllers/user_controller.ex`
  * default CRUD HTML templates in `lib/my_app_web/controllers/user_html`
  * an HTML view collocated with the controller in `lib/my_app_web/controllers/user_html.ex`
  * a schema in `lib/my_app/accounts/user.ex`, with an `users` table
  * a context module in `lib/my_app/accounts.ex` for the accounts API

Additionally, this generator creates the following files:

  * a migration for the schema in `priv/repo/migrations`
  * a controller test module in `test/my_app/controllers/user_controller_test.exs`
  * a context test module in `test/my_app/accounts_test.exs`
  * a context test helper module in `test/support/fixtures/accounts_fixtures.ex`

If the context already exists, this generator injects functions for the given resource into
the context, context test, and context test helper modules.

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
$ mix phx.gen.html Accounts User users --web Accounts
```

Which would generate a `lib/app_web/controllers/accounts/user_controller.ex` and
`lib/app_web/controllers/accounts/user_html.ex`.

## Customizing the context, schema, tables and migrations

In some cases, you may wish to bootstrap HTML templates, controllers,
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