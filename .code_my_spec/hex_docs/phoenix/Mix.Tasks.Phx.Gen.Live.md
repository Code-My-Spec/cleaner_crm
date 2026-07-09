# Mix.Tasks.Phx.Gen.Live

Generates LiveView, templates, and context for a resource.

The format is:

```console
$ mix phx.gen.live [<context>] <schema> <table> <attr:type> [<attr:type>...]
```

For example:

```console
$ mix phx.gen.live User users name:string age:integer
```

Will generate a `User` schema for the `users` table within the `Users` context,
with the attributes `name` (as a string) and `age` (as an integer).

You can also explicitly pass the context name as argument, whenever the context
is well defined:

```console
$ mix phx.gen.live Accounts User users name:string age:integer
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
  * a schema in `lib/app/accounts/user.ex`, with a `users` table
  * a LiveView in `lib/app_web/live/user_live/show.ex`
  * a LiveView in `lib/app_web/live/user_live/index.ex`
  * a LiveView in `lib/app_web/live/user_live/form.ex`
  * a components module in `lib/app_web/components/core_components.ex`
    if none exists

After file generation is complete, there will be output regarding required
updates to the `lib/app_web/router.ex` file.

    Add the live routes to your browser scope in lib/app_web/router.ex:

      live "/users", UserLive.Index, :index
      live "/users/new", UserLive.Form, :new
      live "/users/:id", UserLive.Show, :show
      live "/users/:id/edit", UserLive.Form, :edit

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

By default, the LiveView modules are defined within a folder named
after the schema, such as `lib/app_web/live/user_live`. You can add
additional namespaces by passing the `--web` flag with a module name,
for example:

```console
$ mix phx.gen.live Accounts User users --web Accounts name:string
```

Which would generate the LiveViews in `lib/app_web/live/accounts/user_live/`,
namespaced `AppWeb.Accounts.UserLive` instead of `AppWeb.UserLive`.

## Customizing the context, schema, tables and migrations

In some cases, you may wish to bootstrap HTML templates, LiveViews,
and tests, but leave internal implementation of the context or schema
to yourself. You can use the `--no-context` and `--no-schema` flags
flags for file generation control. Note `--no-context` implies `--no-schema`:

```console
$ mix phx.gen.live Accounts User users --no-context name:string
```

In the cases above, tests are still generated, but they will all fail.

You can also change the table name or configure the migrations to
use binary ids for primary keys, see `mix help phx.gen.schema` for more
information.