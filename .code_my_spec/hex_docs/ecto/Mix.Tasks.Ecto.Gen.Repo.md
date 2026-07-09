# Mix.Tasks.Ecto.Gen.Repo

Generates a new repository.

The repository will be placed in the `lib` directory.

## Examples

    $ mix ecto.gen.repo -r Custom.Repo

This generator will automatically open the config/config.exs
after generation if you have `ECTO_EDITOR` set in your environment
variable.

## Command line options

  * `-r`, `--repo` - the repo to generate