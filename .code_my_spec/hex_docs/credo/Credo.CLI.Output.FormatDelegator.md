# Credo.CLI.Output.FormatDelegator

This module can be used to easily delegate print-statements for different
formats to different modules.

Example:

    use Credo.CLI.Output.FormatDelegator,
      default: Credo.CLI.Command.Suggest.Output.Default,
      flycheck: Credo.CLI.Command.Suggest.Output.FlyCheck,
      oneline: Credo.CLI.Command.Suggest.Output.Oneline,
      json: Credo.CLI.Command.Suggest.Output.Json