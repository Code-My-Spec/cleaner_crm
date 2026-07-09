# FileSystem.Backends.FSInotify

File system backend for GNU/Linux, FreeBSD, DragonFly and OpenBSD.

This file is a fork from https://github.com/synrc/fs.

## Backend Options

  * `:recursive` (bool, default: true), monitor directories and their contents recursively.

## Executable File Path

Useful when running `:file_system` with escript.

The default listener executable file is found through finding `inotifywait` from
`$PATH`.

Two ways to customize the executable file path:

  * Module config with `config.exs`:

    ```elixir
    config :file_system, :fs_inotify,
      executable_file: "YOUR_EXECUTABLE_FILE_PATH"`
    ```

  * System environment variable:

    ```
    export FILESYSTEM_FSINOTIFY_EXECUTABLE_FILE="YOUR_EXECUTABLE_FILE_PATH"`
    ```