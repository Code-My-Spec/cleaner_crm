# Mix.Tasks.Compile.Spex

Compiles `.exs` spex files and enforces boundary constraints.

This compiler ensures that spex (executable specification) files respect
module boundaries defined in the host application. When combined with
the `boundary` library, it prevents spex tests from "reaching in" to
application internals — enforcing true outside-in, black-box testing.

## Why This Exists

Normally, `.exs` files are not checked by Boundary because they aren't
part of the standard compilation pipeline. This compiler:

1. Compiles spex files through `Kernel.ParallelCompiler`
2. Re-attaches Boundary's tracer so cross-module references are tracked
3. Runs Boundary's validation against those references
4. Reports violations as compiler diagnostics

The result: if a spex file tries to call an internal module directly
(instead of going through the approved public interface like ScenicMCP),
you get a clear compiler warning.

## Setup

Add both `:boundary` and `:spex` to your project's compilers list.
The `:boundary` compiler must come before `:elixir` so its tracer
captures module references, and `:spex` must come after `:app`:

    def project do
      [
        compilers: [:boundary] ++ Mix.compilers() ++ [:spex],
        ...
      ]
    end

Configure the glob pattern and boundary under the `:spex` key:

    def project do
      [
        spex: [
          pattern: "test/spex/**/*_spex.exs",
          boundary: MyApp.Spex
        ],
        ...
      ]
    end

The `:boundary` option forces all spex modules into a specific boundary,
regardless of their module name. This is the key mechanism for black-box
enforcement — define a boundary that can only depend on your testing
interface (e.g., ScenicMcp) and all spex modules will be confined to it.

## Example Boundary Setup

In your application, define the spex boundary:

    # lib/my_app/spex.ex
    defmodule MyApp.Spex do
      use Boundary, deps: [ScenicMcp], exports: []
    end

Any spex file that tries to call `MyApp.SomeInternalModule` directly
will produce a boundary violation warning at compile time.

## Flags

  * `--spex-pattern` (`-p`) — glob pattern for .exs files to compile