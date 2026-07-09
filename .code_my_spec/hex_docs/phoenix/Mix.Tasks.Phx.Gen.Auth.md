# Mix.Tasks.Phx.Gen.Auth

Generates authentication logic and related views for a resource.

```console
$ mix phx.gen.auth Accounts User users
```

The first argument is the context module followed by the schema module
and its plural name (used as the schema table name). The example above
will generate an `Accounts` context module with two schemas inside:
`User` and `UserToken`. You may name the context and schema according
to your preferences. For example:

```console
$ mix phx.gen.auth Identity Client clients
```

Will generate an `Identity` context with `Client` and `ClientToken` inside.
Additional information and security considerations are detailed in the
[`mix phx.gen.auth` guide](mix_phx_gen_auth.md).

> #### A note on scopes {: .info}
>
> `mix phx.gen.auth` creates a scope named after the schema by default.
> You can read more about scopes in the [Scopes guide](scopes.md).

## LiveView vs conventional Controllers & Views

Authentication views can either be generated to use LiveView by passing
the `--live` option, or they can use conventional Phoenix
Controllers & Views by passing `--no-live`.

If neither of these options are provided, a prompt will be displayed.

Using the `--live` option is advised if you plan on using LiveView
elsewhere in your application. The user experience when navigating between
LiveViews can be tightly controlled, allowing you to let your users navigate
to authentication views without necessarily triggering a new HTTP request
each time (which would result in a full page load).

## Mixing magic link and password registration

`mix phx.gen.auth` generates email based authentication, which assumes the user who
owns the email address has control over the account. Therefore, it is extremely
important to void all access tokens once the user confirms their account for the first
time, and we do so by revoking all tokens upon confirmation.

However, if you allow users to create an account with password, you must also
require them to be logged in by the time of confirmation, otherwise you may be
vulnerable to credential pre-stuffing, as the following attack is possible:

1. An attacker registers a new account with the email address of their target, anticipating
   that the target creates an account at a later point in time.
2. The attacker sets a password when registering.
3. The target registers an account and sees that their email address is already in use.
4. The target logs in by magic link, but does not change the existing password.
5. The attacker maintains access using the password they previously set.

This is why the default implementation raises whenever a user tries to log in for the first
time by magic link and there is a password set. If you add registration with email and
password, then you must require the user to be logged in to confirm their account.
If they don't have a password (because it was set by the attacker), then they can set one
via a "Forgot your password?"-like workflow.

## Password hashing

The password hashing mechanism defaults to `bcrypt` for
Unix systems and `pbkdf2` for Windows systems. Both
systems use the [Comeonin interface](https://comeonin.hexdocs.pm/).

The password hashing mechanism can be overridden with the
`--hashing-lib` option. The following values are supported:

  * `bcrypt` - [bcrypt_elixir](https://hex.pm/packages/bcrypt_elixir)
  * `pbkdf2` - [pbkdf2_elixir](https://hex.pm/packages/pbkdf2_elixir)
  * `argon2` - [argon2_elixir](https://hex.pm/packages/argon2_elixir)

We recommend developers to consider using `argon2`, which
is the most robust of all 3. The downside is that `argon2`
is quite CPU and memory intensive, and you will need more
powerful instances to run your applications on.

For more information about choosing these libraries, see the
[Comeonin project](https://github.com/riverrun/comeonin).

## Multiple invocations

You can invoke this generator multiple times. This is typically useful
if you have distinct resources that go through distinct authentication
workflows:

    $ mix phx.gen.auth Store User users
    $ mix phx.gen.auth Backoffice Admin admins

Note that when invoking `phx.gen.auth` multiple times, it will also generate
multiple [scopes](guides/authn_authz/scopes.md). Typically, only one scope is needed,
thus you will probably want to customize the generated code afterwards. Also, it
is expected that the generated code is not fully free of conflicts. One example is the
browser pipeline, which will try to assign both scopes as `:current_scope` by default.
You can customize the generated assign key with the `--assign-key` option.

## Binary ids

The `--binary-id` option causes the generated migration to use
`binary_id` for its primary key and foreign keys.

## Default options

This generator uses default options provided in the `:generators`
configuration of your application. These are the defaults:

    config :your_app, :generators,
      binary_id: false,
      sample_binary_id: "11111111-1111-1111-1111-111111111111"

You can override those options per invocation by providing corresponding
switches, e.g. `--no-binary-id` to use normal ids despite the default
configuration.

## Custom table names

By default, the table name for the migration and schema will be
the plural name provided for the resource. To customize this value,
a `--table` option may be provided. For example:

    $ mix phx.gen.auth Accounts User users --table accounts_users

This will cause the generated tables to be named `"accounts_users"` and `"accounts_users_tokens"`.

## Custom scope name

By default, the scope name is the same as the schema name. You can customize the scope name by passing the `--scope` option. For example:

```console
$ mix phx.gen.auth Accounts User users --scope app_user
```

This will generate a scope named `app_user` instead of `user`. You can read more about scopes in the [Scopes guide](scopes.md).

Additionally, the scope's assign key can be customized by passing the `--assign-key` option. For example:

```console
$ mix phx.gen.auth Accounts User users --assign-key current_user_scope
```

This is useful when you want to run `mix phx.gen.auth` multiple times in the same project, but note that
often it might make more sense to reuse the same scope with additional fields instead of separate scopes.