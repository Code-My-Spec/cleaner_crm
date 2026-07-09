# Credo.Check

`Check` modules represent the checks which are run during Credo's analysis.

Example:

    defmodule MyCheck do
      use Credo.Check, category: :warning, base_priority: :high

      def run(%SourceFile{} = source_file, params) do
        #
      end
    end

The check can be configured by passing the following
options to `use Credo.Check`:

- `:base_priority`  Sets the checks's base priority (`:low`, `:normal`, `:high`, `:higher` or `:ignore`).
- `:category`       Sets the check's category (`:consistency`, `:design`, `:readability`, `:refactor`  or `:warning`).
- `:elixir_version` Sets the check's version requirement for Elixir (defaults to `>= 0.0.1`).
- `:explanations`   Sets explanations displayed for the check, e.g.

    ```elixir
    [
      check: "...",
      params: [
        param1: "Your favorite number",
        param2: "Online/Offline mode"
      ]
    ]
    ```

- `:param_defaults` Sets the default values for the check's params (e.g. `[param1: 42, param2: "offline"]`)
- `:tags`           Sets the tags for this check (list of atoms, e.g. `[:tag1, :tag2]`)

Please also note that these options to `use Credo.Check` are just a convenience to implement the `Credo.Check`
behaviour. You can implement any of these by hand:

    defmodule MyCheck do
      use Credo.Check

      def category, do: :warning

      def base_priority, do: :high

      def explanations do
        [
          check: "...",
          params: [
            param1: "Your favorite number",
            param2: "Online/Offline mode"
          ]
        ]
      end

      def param_defaults, do: [param1: 42, param2: "offline"]

      def run(%SourceFile{} = source_file, params) do
        #
      end
    end

The `run/2` function of a Check module takes two parameters: a source file and a list of parameters for the check.
It has to return a list of found issues.

## __using__/1

Returns an ID that can be used to identify the check.

## format_issue/3

format_issue takes an issue_meta and returns an issue.
The resulting issue can be made more explicit by passing the following
options to `format_issue/2`:

- `:priority`     Sets the issue's priority.
- `:trigger`      Sets the issue's trigger, i.e. the text causing the issue (see `Credo.Check.Warning.IoInspect`).
- `:line_no`      Sets the issue's line number. Tries to find `column` if `:trigger` is supplied.
- `:column`       Sets the issue's column.
- `:exit_status`  Sets the issue's exit_status.
- `:severity`     Sets the issue's severity.
- `:category`     Sets the issue's category.

## to_exit_status/1

Converts a given category to an exit status