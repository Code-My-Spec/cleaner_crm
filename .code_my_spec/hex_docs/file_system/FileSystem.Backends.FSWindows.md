# FileSystem.Backends.FSWindows

File system backend for Windows.

Need binary executable file packaged in to use this backend.

This file is a fork from https://github.com/synrc/fs.

## Backend Options

  * `:recursive` (bool, default: true), monitor directories and their contents recursively

## Executable File Path

Useful when running `:file_system` with escript.

The default listener executable file is `priv/inotifywait.exe` within the
folder of `:file_system` application.

Two ways to customize the executable file path:

  * Module config with `config.exs`:

    ```elixir
    config :file_system, :fs_windows,
      executable_file: "YOUR_EXECUTABLE_FILE_PATH"`
    ```

  * System environment variable:

    ```
    export FILESYSTEM_FSWINDOWS_EXECUTABLE_FILE="YOUR_EXECUTABLE_FILE_PATH"`
    ```