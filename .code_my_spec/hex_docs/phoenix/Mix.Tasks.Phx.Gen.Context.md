# Mix.Tasks.Phx.Gen.Context

Generates a context with functions around an Ecto schema.

```console
$ mix phx.gen.context Accounts User users name:string age:integer
```

The first argument is the context module followed by the schema module
and its plural name (used as the schema table name).

The context is an Elixir module that serves as an API boundary for
the given resource. A context often holds many related resources.
Therefore, if the context already exists, it will be augmented with
functions for the given resource.

> Note: A resource may also be split
> over distinct contexts (such as Accounts.User and Payments.User).

The schema is responsible for mapping the database fields into an
Elixir struct.

Overall, this generator will add the following files to `lib/your_app`:

  * a context module in `accounts.ex`, serving as the API boundary
  * a schema in `accounts/user.ex`, with a `users` table

A migration file for the repository and test files for the context
will also be generated.

The generated migration can be skipped with `--no-migration`.

## Scopes

If your application configures its own default [scope](scopes.md), then this generator
will automatically make sure all of your context operations are correctly scoped.
You can pass the `--no-scope` flag to disable the scoping.

## Generating without a schema

In some cases, you may wish to bootstrap the context module and
tests, but leave internal implementation of the context and schema
to yourself. Use the `--no-schema` flags to accomplish this.

## `--table`

By default, the table name for the migration and schema will be
the plural name provided for the resource. To customize this value,
a `--table` option may be provided. For example:

    $ mix phx.gen.context Accounts User users --table cms_users

## `--binary-id`

Generated migration can use `binary_id` for schema's primary key
and its references with option `--binary-id`.

## Default options

This generator uses default options provided in the `:generators`
configuration of your application. These are the defaults:

    config :your_app, :generators,
      migration: true,
      binary_id: false,
      timestamp_type: :naive_datetime,
      sample_binary_id: "11111111-1111-1111-1111-111111111111"

You can override those options per invocation by providing corresponding
switches, e.g. `--no-binary-id` to use normal ids despite the default
configuration or `--migration` to force generation of the migration.

Read the documentation for `phx.gen.schema` for more information on
attributes.

## Skipping prompts

This generator will prompt you if there is an existing context with the same
name, in order to provide more instructions on how to correctly use phoenix contexts.
You can skip this prompt and automatically merge the new schema access functions and tests into the
existing context using `--merge-with-existing-context`. To prevent changes to
the existing context and exit the generator, use `--no-merge-with-existing-context`.