# Credo.Test.Case

Conveniences for testing Credo custom checks and plugins.

This module can be used in your test cases, like this:

    use Credo.Test.Case

Using this module will:

* import all the functions from this module
* make the test case `:async` by default (use `use Credo.Test.Case, async: false` to opt out)

## Testing custom checks

Suppose we have a custom check in our project that checks whether or not
the "FooBar rules" are applied (one of those *very* project-specific things).

    defmodule MyProject.MyCustomChecks.FooBar do
      use Credo.Check, category: :warning, base_priority: :high

      def run(%SourceFile{} = source_file, params) do
        # ... implement all the "FooBar rules" ...
      end
    end

When we want to test this check, we can use `Credo.Test.Case` for convenience:

    defmodule MyProject.MyCustomChecks.FooBarTest do
      use Credo.Test.Case

      alias MyProject.MyCustomChecks.FooBar

      test "it should NOT report expected code" do
        """
        defmodule CredoSampleModule do
          # ... some good Elixir code ...
        end
        """
        |> to_source_file()
        |> run_check(FooBar)
        |> refute_issues()
      end

      test "it should report code that violates the FooBar rule" do
        """
        defmodule CredoSampleModule do
          # ... some Elixir code that violates the FooBar rule ...
        end
        """
        |> to_source_file()
        |> run_check(FooBar)
        |> assert_issues()
      end
    end

This is as simple and mundane as it looks (which is a good thing):
We have two tests: one for the good case, one for the bad case.
In each, we create a source file representation from a heredoc, run our custom check and assert/refute the issues
we expect.

## Asserting found issues

Once we get to know domain a little better, we can add more tests, typically testing for other bad cases in which
our check should produce issues.

Note that there are two assertion functions for this: `assert_issue/2` and `assert_issues/2`, where the first one
ensures that there is a single issue and the second asserts that there are at least two issues.

Both functions take an optional `callback` as their second parameter, which is called with the `issue` or the
list of `issues` found, which makes it convenient  to check for the issues properties ...

    """
    # ... any Elixir code ...
    """
    |> to_source_file()
    |> run_check(FooBar)
    |> assert_issue(fn issue -> assert issue.trigger == "foo" end)

... or properties of the list of issues:

    """
    # ... any Elixir code ...
    """
    |> to_source_file()
    |> run_check(FooBar)
    |> assert_issue(fn issues -> assert Enum.count(issues) == 3 end)

## Testing checks that analyse multiple source files

For checks that analyse multiple source files, like Credo's consistency checks, we can use `to_source_files/1` to
create

    [
      """
      # source file 1
      """,
      """
      # source file 2
      """
    ]
    |> to_source_files()
    |> run_check(FooBar)
    |> refute_issues()

If our check needs named source files, we can always use `to_source_file/2` to create individually named source
files and combine them into a list:

    source_file1 =
      """
      # source file 1
      """
      |> to_source_file("foo.ex")

    source_file2 =
      """
      # source file 2
      """
      |> to_source_file("bar.ex")

    [source_file1, source_file2]
    |> run_check(FooBar)
    |> assert_issue(fn issue -> assert issue.filename == "foo.ex" end)

## refute_issues/1

Refutes the presence of any issues.

## assert_issue/2

Asserts the presence of a single issue.

This is useful for saying "in this snippet, there is exactly one issue":

    source_file
    |> run_check(FooBar)
    |> assert_issue()

Giving a pattern, you can say "in this snippet, there should be one issue looking like this":

    source_file
    |> run_check(FooBar)
    |> assert_issue(%{line_no: 3})

The given patterns can contain all fields of `Credo.Issue`
(`:message` can either be a string or a regex):

    source_file
    |> run_check(FooBar)
    |> assert_issue(%{
        message: ~r/should reference/,
        trigger: "foo",
        line_no: 3
      })

If `callback` is given, calls it with the found issue:

    source_file
    |> run_check(FooBar)
    |> assert_issue(fn issue ->
      assert issue.line_no == 3
      assert issue.trigger == "foo"
    end)

## assert_issues/2

Asserts the presence of more than one issue.

This is useful for saying "in this snippet, there is more than one issue":

    source_file
    |> run_check(FooBar)
    |> assert_issues()

If `callback` is given, calls it with the found issues:

    source_file
    |> run_check(FooBar)
    |> assert_issues(fn issues ->
      assert Enum.count(issues) == 3
    end)

If a number is given, checks that the count of issues matches:

    source_file
    |> run_check(FooBar)
    |> assert_issues(3)

## assert_issues_match/2

Asserts the presence of one or more issues based on the given patterns.

This is useful for saying "in this snippet, there should be issues looking like this":

    source_file
    |> run_check(FooBar)
    |> assert_issues_match([
      %{line_no: 3},
      %{line_no: 6}
    ])

The given patterns can contain all fields of `Credo.Issue`:

    source_file
    |> run_check(FooBar)
    |> assert_issues_match([
      %{
        message: "Module attribute @config_7 causes trouble",
        trigger: "@config_7",
        line_no: 8,
        column: 13
      },
      %{
        message: "Module attribute @config_9 causes trouble",
        trigger: "@config_9",
        line_no: 10,
        column: 13
      }
    ])

  One can combine this with `assert_issues/2` to make sure there are only the issues one expects:

    source_file
    |> run_check(FooBar)
    |> assert_issues(2)
    |> assert_issues_match([
      %{line_no: 3},
      %{line_no: 6}
    ])

## assert_issue_matches/2

Asserts the presence of one or more issues based on the given patterns.

This is useful for saying "in this snippet, there should be at least one issue looking like this":

    source_file
    |> run_check(FooBar)
    |> assert_issue_matches(%{line_no: 3})

The given patterns can contain all fields of `Credo.Issue`:

    source_file
    |> run_check(FooBar)
    |> assert_issue_matches(%{
        message: "Module attribute @config_7 causes trouble",
        trigger: "@config_7",
        line_no: 8,
        column: 13
      })

## run_check/3

Runs the given `check` on the given `source_file` using the given `params`.

    "x = 5"
    |> to_source_file()
    |> run_check(MyProject.MyCheck, foo_parameter: "bar")

## to_source_file/1

Converts the given `source` string to a `%SourceFile{}`.

    "x = 5"
    |> to_source_file()

## to_source_file/2

Converts the given `source` string to a `%SourceFile{}` with the given `filename`.

    "x = 5"
    |> to_source_file("simple.ex")

## to_source_files/1

Converts the given `list` of source code strings to a list of `%SourceFile{}` structs.

    ["x = 5", "y = 6"]
    |> to_source_files()