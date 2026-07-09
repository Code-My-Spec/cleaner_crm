# CodeMySpecGenerators.Generator



## app_config/0

Detects target app module names from the Mix project configuration.

Returns a map with:
- `:app` — OTP app atom
- `:app_module` — base module name (e.g., "MyApp")
- `:web_module` — web module name (e.g., "MyAppWeb")
- `:repo_module` — repo module (e.g., "MyApp.Repo")
- `:pubsub` — PubSub module (e.g., "MyApp.PubSub")
- `:endpoint` — endpoint module (e.g., "MyAppWeb.Endpoint")
- `:mailer` — mailer module (e.g., "MyApp.Mailer")

## template_paths/0

Returns the paths to search for template files.

Searches the code_my_spec_generators app's priv/templates first,
then falls back to the current directory.

## copy_templates/3

Copies template files from priv/templates to the target app.

Wraps `Mix.Phoenix.copy_from/4` using our template paths.

## ensure_dep_ran!/2

Verifies that a prerequisite generator has been run by checking for expected files.

## binding/0

Returns standard EEx binding keyword list from app config.

## migration_timestamp/1

Generates a unique migration timestamp.

If called multiple times within the same second, increments by 1 second
to avoid collisions.

## lib_path/1

Returns the lib path for the context app.

## web_lib_path/1

Returns the web lib path.

## test_path/1

Returns the test path for the context app.

## web_test_path/1

Returns the web test path.

## print_shell_instructions/1

Prints post-generation instructions.