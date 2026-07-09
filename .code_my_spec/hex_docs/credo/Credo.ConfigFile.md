# Credo.ConfigFile

`ConfigFile` structs represent all loaded and merged config files in a run.

## read_or_default/4

Returns Execution struct representing a consolidated Execution for all `.credo.exs`
files in `relevant_directories/1` merged into the default configuration.

- `config_name`: name of the configuration to load
- `safe`: if +true+, the config files are loaded using static analysis rather
          than `Code.eval_string/1`

## read_from_file_path/5

Returns the provided config_file merged into the default configuration.

- `config_file`: full path to the custom configuration file
- `config_name`: name of the configuration to load
- `safe`: if +true+, the config files are loaded using static analysis rather
          than `Code.eval_string/1`

## relevant_directories/1

Returns all parent directories of the given `dir` as well as each `./config`
sub-directory.

## merge/1

Merges the given structs from left to right, meaning that later entries
overwrites earlier ones.

    merge(base, other)

Any options in `other` will overwrite those in `base`.

The `files:` field is merged, meaning that you can define `included` and/or
`excluded` and only override the given one.

The `checks:` field is merged.