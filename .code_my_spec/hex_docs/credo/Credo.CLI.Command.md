# Credo.CLI.Command

`Command` is used to describe commands which can be executed from the command line.

The default command is `Credo.CLI.Command.Suggest.SuggestCommand`.

A basic command that writes "Hello World" can be implemented like this:

    defmodule HelloWorldCommand do
      use Credo.CLI.Command

      alias Credo.CLI.Output.UI

      def call(_exec, _opts) do
        UI.puts([:yellow, "Hello ", :orange, "World"])
      end
    end

## __using__/1

Is called when a Command is initialized.

The `init/1` functions receives an `exec` struct and must return a (modified) `Credo.Execution`.

This can be used to initialize Execution pipelines for the current Command:

    defmodule FooTask do
      use Credo.Execution.Task

      def init(exec) do
        Execution.put_pipeline(exec, __MODULE__,
          run_my_thing: [
            {RunMySpecialThing, []}
          ],
          filter_results: [
            {FilterResults, []}
          ],
          print_results: [
            {PrintResultsAndSummary, []}
          ]
        )
      end
    end