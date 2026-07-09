# Credo.Plugin

Plugins are module which can provide additional functionality to Credo.

A plugin is basically just a module that provides an `init/1` callback.

    defmodule CredoDemoPlugin do
      def init(exec) do
        # but what do we do here??
        exec
      end
    end

The `Credo.Plugin` module provides a number of functions for extending Credo's core features.

    defmodule CredoDemoPlugin do
      @config_file File.read!(".credo.exs")

      import Credo.Plugin

      def init(exec) do
        exec
        |> register_default_config(@config_file)
        |> register_command("demo", CredoDemoPlugin.DemoCommand)
        |> register_cli_switch(:castle, :string, :X)
        |> prepend_task(:set_default_command, CredoDemoPlugin.SetDemoAsDefaultCommand)
      end
    end

## register_cli_switch/5

Adds a CLI switch to Credo.

For demo purposes, we are writing a command called `demo` (see `register_command/3`):

    # credo_demo_plugin/demo_command.ex
    defmodule CredoDemoPlugin do
      import Credo.Plugin

      def init(exec) do
        exec
        |> register_command("demo", CredoDemoPlugin.DemoCommand)
      end
    end

    # credo_demo_plugin/demo_command.ex
    defmodule CredoDemoPlugin.DemoCommand do
      alias Credo.CLI.Output.UI
      alias Credo.Execution

      def call(exec, _) do
        castle = Execution.get_plugin_param(exec, CredoDemoPlugin, :castle)

        UI.puts("By the power of #{castle}!")

        exec
      end
    end

Since Plugins can be configured by params in `.credo.exs`, we can add the `:castle` param:

    # .credo.exs
    {CredoDemoPlugin, [castle: "Grayskull"]}

And get the following output:

```bash
$ mix credo demo
By the power of Grayskull!
```

Plugins can provide custom CLI options as well, so we can do something like:

```bash
$ mix credo demo --castle Winterfell
Unknown switch: --castle
```

Registering a custom CLI switch for this is easy:

    defmodule CredoDemoPlugin do
      import Credo.Plugin

      def init(exec) do
        exec
        |> register_command("demo", CredoDemoPlugin.DemoCommand)
        |> register_cli_switch(:castle, :string, :X)
      end
    end

Every registered CLI switch is automatically converted into a plugin param of the same name, which is why we get the following output:

```bash
$ mix credo demo --castle Winterfell
By the power of Winterfell!

$ mix credo demo -X Camelot
By the power of Camelot!
```

Plugin authors can also provide a function to control the plugin param's name and value more granularly:

    defmodule CredoDemoPlugin do
      import Credo.Plugin

      def init(exec) do
        exec
        |> register_command("demo", CredoDemoPlugin.DemoCommand)
        |> register_cli_switch(:kastle, :string, :X, fn(switch_value) ->
          {:castle, String.upcase(switch_value)}
        end)
      end
    end

And get the following output:

```bash
$ mix credo demo --kastle Winterfell
By the power of WINTERFELL!
```

## register_default_config/2

Registers the contents of a config file.

This registers the contents of a config file as default config, loading it after Credo's own default config but before the [config files loaded from the current working directory](config_file.html#transitive-configuration-files).

    defmodule CredoDemoPlugin do
      @config_file File.read!(".credo.exs")

      import Credo.Plugin

      def init(exec) do
        register_default_config(exec, @config_file)
      end
    end