# Credo.Check.Consistency.Collector

A behavior for modules that walk through source files and
identify consistency issues.

When defining a consistency check, you would typically use
this structure for the main module, responsible
for formatting issue messages:

    defmodule Credo.Check.Consistency.SomeCheck do
      use Credo.Check, run_on_all: true

      @collector Credo.Check.Consistency.SomeCheck.Collector

      def run(source_files, exec, params) when is_list(source_files) do
        issue_formatter = &issues_for/3

        @collector.find_and_append_issues(source_files, exec, params, issue_formatter)
      end

      defp issues_for(expected, source_file, params) do
        issue_meta = IssueMeta.for(source_file, params)
        issue_locations =
          @collector.find_locations_not_matching(expected, source_file)

        Enum.map(issue_locations, fn(location) ->
          format_issue issue_meta, message: ... # write an issue message
        end)
      end

The actual analysis would be performed by another module
implementing the `Credo.Check.Consistency.Collector` behavior:

    defmodule Credo.Check.Consistency.SomeCheck.Collector do
      use Credo.Check.Consistency.Collector

      def collect_matches(source_file, params) do
        # ...
      end

      def find_locations_not_matching(expected, source_file) do
        # ...
      end
    end

Read further for more information on `collect_matches/2`,
`find_locations_not_matching/2`, and `issue_formatter`.

## __using__/1

`issue_formatter` may call the `@collector.find_locations_not_matching/2`
function to obtain additional metadata for each occurrence of
an unexpected match in a given file.

An example implementation that returns a list of line numbers on
which unexpected occurrences were found:

    def find_locations_not_matching(expected, source_file) do
      traverse(source_file, fn(match, line_no, acc) ->
        if match != expected do
          acc ++ [line_no]
        else
          acc
        end
      end)
    end

    defp traverse(source_file, fun), do: ...