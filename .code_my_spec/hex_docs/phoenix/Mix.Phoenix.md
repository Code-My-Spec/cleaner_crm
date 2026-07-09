# Mix.Phoenix



## eval_from/3

Evals EEx files from source dir.

Files are evaluated against EEx according to
the given binding.

## copy_from/4

Copies files from source dir to target dir
according to the given map.

Files are evaluated against EEx according to
the given binding.

## inflect/1

Inflects path, scope, alias and more from the given name.

## Examples

    iex> Mix.Phoenix.inflect("user")
    [alias: "User",
     human: "User",
     base: "Phoenix",
     web_module: "PhoenixWeb",
     module: "Phoenix.User",
     scoped: "User",
     singular: "user",
     path: "user"]

    iex> Mix.Phoenix.inflect("Admin.User")
    [alias: "User",
     human: "User",
     base: "Phoenix",
     web_module: "PhoenixWeb",
     module: "Phoenix.Admin.User",
     scoped: "Admin.User",
     singular: "user",
     path: "admin/user"]

    iex> Mix.Phoenix.inflect("Admin.SuperUser")
    [alias: "SuperUser",
     human: "Super user",
     base: "Phoenix",
     web_module: "PhoenixWeb",
     module: "Phoenix.Admin.SuperUser",
     scoped: "Admin.SuperUser",
     singular: "super_user",
     path: "admin/super_user"]

## check_module_name_availability!/1

Checks the availability of a given module name.

## base/0

Returns the module base name based on the configuration value.

    config :my_app
      namespace: My.App

## context_base/1

Returns the context module base name based on the configuration value.

    config :my_app
      namespace: My.App

## otp_app/0

Returns the OTP app from the Mix project configuration.

## modules/0

Returns all compiled modules in a project.

## generator_paths/0

The paths to look for template files for generators.

Defaults to checking the current app's `priv` directory,
and falls back to Phoenix's `priv` directory.

## in_umbrella?/1

Checks if the given `app_path` is inside an umbrella.

## web_path/2

Returns the web prefix to be used in generated file specs.

## context_app_path/2

Returns the context app path prefix to be used in generated context files.

## context_lib_path/2

Returns the context lib path to be used in generated context files.

## context_test_path/2

Returns the context test path to be used in generated context files.

## context_app/0

Returns the OTP context app.

## web_test_path/2

Returns the test prefix to be used in generated file specs.

## prompt_for_conflicts/1

Prompts to continue if any files exist.

## web_module/1

Returns the web module prefix.

## ensure_live_view_compat!/1

Ensures user's LiveView is compatible with the current generators.