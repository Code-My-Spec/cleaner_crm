# Mix.Tasks.Compile.Boundary

Verifies cross-module function calls according to defined boundaries.

This compiler reports all cross-boundary function calls which are not permitted, according to
the current definition of boundaries. For details on defining boundaries, see the docs for the
`Boundary` module.

## Usage

Once you have configured the boundaries, you need to include the compiler in `mix.exs`:

```
defmodule MySystem.MixProject do
  # ...

  def project do
    [
      compilers: [:boundary] ++ Mix.compilers(),
      # ...
    ]
  end

  # ...
end
```

When developing a library, it's advised to use this compiler only in `:dev` and `:test`
environments:

```
defmodule Boundary.MixProject do
  # ...

  def project do
    [
      compilers: extra_compilers(Mix.env()) ++ Mix.compilers(),
      # ...
    ]
  end

  # ...

  defp extra_compilers(:prod), do: []
  defp extra_compilers(_env), do: [:boundary]
end
```

## Warnings

Every invalid cross-boundary usage is reported as a compiler warning. Consider the following example:

```
defmodule MySystem.User do
  def auth() do
    MySystemWeb.Endpoint.url()
  end
end
```

Assuming that calls from `MySystem` to `MySystemWeb` are not allowed, you'll get the following warning:

```
$ mix compile

warning: forbidden reference to MySystemWeb
  (references from MySystem to MySystemWeb are not allowed)
  lib/my_system/user.ex:3
```

Since the compiler emits warnings, `mix compile` will still succeed, and you can normally start
your system, even if some boundary rules are violated. The compiler doesn't force you to immediately
fix these violations, which is a deliberate decision made to avoid disrupting the development flow.

At the same time, it's worth enforcing boundaries on the CI. This can easily be done by providing
the `--warnings-as-errors` option to `mix compile`.