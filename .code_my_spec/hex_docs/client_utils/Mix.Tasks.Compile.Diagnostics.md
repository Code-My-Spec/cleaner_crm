# Mix.Tasks.Compile.Diagnostics

Registers `after_compiler` hooks that write diagnostics to a JSONL file.

Add `:diagnostics` as the **first** compiler so the hooks are registered
before `:elixir` runs. This ensures diagnostics are written even when a
syntax error aborts the compiler chain.

    def project do
      [
        compilers: [:diagnostics] ++ Mix.compilers() ++ [:spex],
        diagnostics: [output: "diagnostics.jsonl"],
        ...
      ]
    end

## Options

  * `:output` - output file path, defaults to `"diagnostics.jsonl"`.
    Can also be set via the `DIAGNOSTICS_OUTPUT` env var.

## Project configuration

Options can be set under the `:diagnostics` key:

    def project do
      [
        compilers: [:diagnostics] ++ Mix.compilers() ++ [:spex],
        diagnostics: [output: "build/diagnostics.jsonl"],
        ...
      ]
    end

## write_diagnostics/2

Writes diagnostics to the output file.

Merges diagnostics passed via `extra_diagnostics` (from the after_compiler
callback) with those queried from every compiler that exposes `diagnostics/0`,
deduplicating by file + position + message.