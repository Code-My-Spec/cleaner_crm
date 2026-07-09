# FileSystem.Backends.FSMac

File system backend for MacOS.

The built-in executable file will be compile upon first use.

This file is a fork from https://github.com/synrc/fs.

## Backend Options

  * `:latency` (float, default: 0.5), latency period.

  * `:no_defer` (bool, default: false), enable no-defer latency modifier.
    Works with latency parameter.

    See `FSEvent` API documents
    https://developer.apple.com/documentation/coreservices/kfseventstreamcreateflagnodefer.

  * `:watch_root` (bool, default: false), watch for when the root path has changed.
    Set the flag `true` to monitor events when watching `/tmp/fs/dir` and run
    `mv /tmp/fs /tmp/fx`.

    See `FSEvent` API documents
    https://developer.apple.com/documentation/coreservices/kfseventstreamcreateflagwatchroot.

  * recursive is enabled by default and it can'b be disabled for now.

## Executable File Path

Useful when running `:file_system` with escript.

The default listener executable file is `priv/mac_listener` within the folder of
`:file_system` application.

Two ways to customize the executable file path:

  * Module config with `config.exs`:

    ```elixir
    config :file_system, :fs_mac,
      executable_file: "YOUR_EXECUTABLE_FILE_PATH"`
    ```

  * System environment variable:

    ```
    export FILESYSTEM_FSMAC_EXECUTABLE_FILE="YOUR_EXECUTABLE_FILE_PATH"`
    ```