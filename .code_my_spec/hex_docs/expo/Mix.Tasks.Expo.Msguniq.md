# Mix.Tasks.Expo.Msguniq

Unifies duplicate translations in the given PO file.

By default, this task outputs the file on standard output. If you want to
*overwrite* the given PO file, pass in the `--output` flag.

*This task is available since v0.5.0.*

## Usage

    mix expo.msguniq PO_FILE [--output-file=OUTPUT_FILE]

## Options

* `--output-file` (`-o`) - File to store the output in. `-` for
  standard output. Defaults to `-`.