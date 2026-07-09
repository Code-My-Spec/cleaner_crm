# Credo

Credo builds upon four building blocks:

- `Credo.CLI` - everything related to the command line interface (CLI), which orchestrates the analysis
- `Credo.Execution` - a struct which is handed down the pipeline during analysis
- `Credo.Check` - the default Credo checks
- `Credo.Code` - all analysis tools used by Credo during analysis

## run/1

Runs Credo with the given `argv` and returns its final `Credo.Execution` struct.

Example:

    iex> exec = Credo.run(["--only", "Readability"])
    iex> issues = Credo.Execution.get_issues(exec)
    iex> Enum.count(issues) > 0
    true