# Oban.Plugin

Defines a shared behaviour for Oban plugins.

In addition to implementing the Plugin behaviour, all plugins **must** be a `GenServer`, `Agent`, or
another OTP compliant module.

## Example

Defining a basic plugin that satisfies the minimum behaviour:

    defmodule MyPlugin do
      @behaviour Oban.Plugin

      use GenServer

      @impl Oban.Plugin
      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts, name: opts[:name])
      end

      @impl Oban.Plugin
      def validate(opts) do
        if is_atom(opts[:mode]) do
          :ok
        else
          {:error, "expected opts to have a :mode key"}
        end
      end

      @impl GenServer
      def init(opts) do
        case validate(opts) do
          :ok -> {:ok, opts}
          {:error, reason} -> {:stop, reason}
        end
      end
    end