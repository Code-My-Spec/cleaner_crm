defmodule CleanerCrm.Check.Warning.CleanerCrmSpexDenies do
  use Credo.Check,
    id: "CLEANE0001",
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Project-local WHOLE-module denies for BDD spec files (`_spex.exs`).

      Complements the framework `spex_denied_calls` check (function-level
      denies). Specs drive the app only through public surfaces — LiveView
      routes under `CleanerCrmWeb` and the curated `CleanerCrmSpex.Fixtures`
      bridge. Reaching into contexts or the Repo from a spec bypasses the
      seal and turns the spec into a unit test wearing a costume.

      Denied whole modules:

      - `File`, `:file` — real-disk reads bypass the in-memory environment.
      - `Port` — talks to external programs; use cassettes.
      - `CleanerCrm.Repo` — direct DB access bypasses the public surface.
      - All internal contexts: `CleanerCrm.Clients`, `CleanerCrm.Scheduling`,
        `CleanerCrm.Quoting`, `CleanerCrm.Billing`, `CleanerCrm.Notifications`,
        `CleanerCrm.TimeTracking`, `CleanerCrm.Quality`, `CleanerCrm.Audit`,
        `CleanerCrm.Users`, `CleanerCrm.Accounts`, `CleanerCrm.Integrations` —
        the spec boundary deps only on `CleanerCrmTest` and `CleanerCrmWeb`.

      Seed state through `CleanerCrmSpex.Fixtures`, act through the UI.
      """
    ]

  @denied_whole_modules [
    File,
    Port,
    CleanerCrm.Repo,
    CleanerCrm.Clients,
    CleanerCrm.Scheduling,
    CleanerCrm.Quoting,
    CleanerCrm.Billing,
    CleanerCrm.Notifications,
    CleanerCrm.TimeTracking,
    CleanerCrm.Quality,
    CleanerCrm.Audit,
    CleanerCrm.Users,
    CleanerCrm.Accounts,
    CleanerCrm.Integrations
  ]

  @denied_whole_erlang_modules [:file]

  @doc false
  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if String.ends_with?(filename, "_spex.exs") do
      ctx = %{issue_meta: Context.build(source_file, params, __MODULE__), issues: []}
      Credo.Code.prewalk(source_file, &traverse/2, ctx).issues
    else
      []
    end
  end

  # Aliased Elixir modules — File.*, Port.*, CleanerCrm.<Context>.*
  defp traverse(
         {{:., _, [{:__aliases__, meta, module_parts}, fun]}, _, _args} = ast,
         ctx
       ) do
    module = Module.concat(module_parts)

    if module in @denied_whole_modules do
      {ast, add_issue(ctx, meta, "#{inspect(module)}.#{fun}")}
    else
      {ast, ctx}
    end
  end

  # Erlang modules — :file.*
  defp traverse({{:., _, [erl_mod, fun]}, meta, _args} = ast, ctx)
       when is_atom(erl_mod) do
    if erl_mod in @denied_whole_erlang_modules do
      {ast, add_issue(ctx, meta, "#{inspect(erl_mod)}.#{fun}")}
    else
      {ast, ctx}
    end
  end

  defp traverse(ast, ctx), do: {ast, ctx}

  defp add_issue(ctx, meta, trigger) do
    issue =
      format_issue(
        ctx.issue_meta,
        message:
          "Call to `#{trigger}` is denied in _spex.exs files. Seed state through " <>
            "CleanerCrmSpex.Fixtures and act through the public CleanerCrmWeb surfaces. " <>
            "See .code_my_spec/knowledge/bdd/spex/boundaries.md.",
        trigger: trigger,
        line_no: meta[:line],
        column: meta[:column]
      )

    %{ctx | issues: [issue | ctx.issues]}
  end
end
