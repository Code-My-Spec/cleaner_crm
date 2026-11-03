defmodule CleanerCrmMcp.CodeModeTest do
  use ExUnit.Case, async: true

  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.CodeMode

  defmodule Echo do
    use CleanerCrmMcp.Tool, name: "echo"
    def description, do: "Echo the arguments back.\nLonger text about echo."

    def params,
      do: [
        %{name: "text", type: :string, required: true, description: "What to echo"},
        %{name: "count", type: :integer, required: false, description: "How many"}
      ]

    def example, do: ~s|return echo({ text = "hi" })|

    def call(args, scope),
      do:
        {:ok,
         %{
           "args" => args,
           "account" => scope.active_account_id,
           "list" => [1, 2, 3],
           "none" => nil,
           "d" => ~D[2026-01-02]
         }}
  end

  defmodule Items do
    use CleanerCrmMcp.Tool, name: "list_items", mutates: true
    def description, do: "List items."
    def call(_args, _scope), do: {:ok, [%{"n" => 1}, %{"n" => 2}]}
  end

  defmodule Fails do
    use CleanerCrmMcp.Tool, name: "fails"
    def description, do: "Always fails."
    def call(_args, _scope), do: {:error, "nope"}
  end

  defmodule FailsCs do
    use CleanerCrmMcp.Tool, name: "fails_cs"
    def description, do: "Fails with a changeset."

    def call(_args, _scope) do
      cs =
        {%{}, %{name: :string}}
        |> Ecto.Changeset.cast(%{}, [:name])
        |> Ecto.Changeset.validate_required([:name])

      {:error, cs}
    end
  end

  defmodule Boom do
    use CleanerCrmMcp.Tool, name: "boom"
    def description, do: "Raises."
    def call(_args, _scope), do: raise("kaboom")
  end

  defmodule Lister do
    use CleanerCrmMcp.Tool, name: "sum_list"
    def description, do: "Sums a list."
    def params, do: [%{name: "xs", type: :list, required: true, description: "numbers"}]
    def call(%{"xs" => xs}, _), do: {:ok, Enum.sum(xs)}
  end

  @tools [Echo, Items, Fails, FailsCs, Boom, Lister]

  defp scope, do: %Scope{active_account_id: Ecto.UUID.generate()}

  defp run(script, opts \\ []),
    do: CodeMode.eval(script, scope(), Keyword.put_new(opts, :tools, @tools))

  test "successful call returns nested values" do
    r =
      run(
        ~s|local r = echo({ text = "hi", count = 2 })\nreturn { text = r.args.text, n = r.args.count, list = r.list, d = r.d, none = r.none }|
      )

    assert r.error == nil
    assert r.value == %{"text" => "hi", "n" => 2, "list" => [1, 2, 3], "d" => "2026-01-02"}
  end

  test "scope is passed to the tool" do
    sc = scope()
    r = CodeMode.eval(~s|return echo({ text = "x" }).account|, sc, tools: @tools)
    assert r.value == sc.active_account_id
  end

  test "arrays come back as lists and go in as lists" do
    assert run("return list_items()").value == [%{"n" => 1}, %{"n" => 2}]
    assert run("return sum_list({ xs = {1, 2, 3} })").value == 6
  end

  test "tool error returns nil and an error table" do
    r =
      run(~s|local v, err = fails({})\nreturn { v = v, tool = err.tool, message = err.message }|)

    assert r.value == %{"tool" => "fails", "message" => "nope"}
  end

  test "changeset errors carry details" do
    r = run(~s|local v, err = fails_cs({})\nreturn { m = err.message, d = err.details.name[1] }|)
    assert r.value["d"] == "can't be blank"
    assert r.value["m"] =~ "name"
  end

  test "rejected calls stop the script" do
    for {script, text} <- [
          {~s|return echo({ text = {} })|, "echo: `text` must be a string"},
          {~s|return echo({})|, "`text` is required"},
          {~s|return echo({ text = "a", bogus = 1 })|, "unknown argument `bogus`"}
        ] do
      r = run("print('before')\n" <> script <> "\nprint('after')")
      assert r.error.kind == :rejected_call
      assert r.error.message =~ text
      assert r.prints == ["before"]
    end
  end

  test "a crashing tool stops the script naming it" do
    r = run("return boom({})")
    assert r.error.kind == :crashed
    assert r.error.message =~ "boom crashed"
  end

  test "print is captured, and survives errors" do
    r = run(~s|print("a", 1, true, nil)\nprint("b")\nreturn 1|)
    assert r.prints == ["a\t1\ttrue\tnil", "b"]
    r = run(~s|print("x")\nerror("bad")|)
    assert r.error.kind == :runtime
    assert r.prints == ["x"]
  end

  test "compile and runtime errors" do
    assert run("return (").error.kind == :compile
    r = run("local x = nil\nreturn x.y")
    assert r.error.kind == :runtime
  end

  test "infinite loop hits the budget" do
    r = run("while true do end", max_instructions: 10_000)
    assert r.error.kind == :instruction_budget
  end

  test "wall-clock timeout" do
    r = run("while true do end", max_instructions: :infinity, timeout: 200)
    assert r.error.kind == :timeout
  end

  test "deep recursion and giant strings" do
    assert run("local function f() return 1 + f() end\nreturn f()").error.kind == :call_depth
    assert run(~s|return string.rep("x", 10000000)|).error.kind == :result_too_large
  end

  test "sandbox blocks os and io" do
    assert run(~s|return os.execute("ls")|).error.kind == :sandboxed
    assert run(~s|return io.open("/etc/passwd")|).error.kind == :sandboxed
    assert run(~s|return require("os")|).error.kind == :sandboxed
    assert run(~s|return dofile("x")|).error.kind == :sandboxed
  end

  test "unknown function suggests tool_docs and close names" do
    r = run("return list_item({})")
    assert r.error.kind == :runtime
    assert r.error.message =~ "list_items"
    assert r.error.message =~ "tool_docs"
    assert run("return zzz()").error.message =~ "tool_docs"
  end

  test "docs index, page, names, search, unknown" do
    index = CodeMode.docs(tools: @tools)
    assert index =~ "echo - Echo the arguments back."
    assert index =~ "## Other"

    page = CodeMode.docs(name: "echo", tools: @tools)
    assert page =~ "# echo"
    assert page =~ "Longer text about echo."
    assert page =~ "| text | string | yes | What to echo |"
    assert page =~ ~s|return echo({ text = "hi" })|
    refute page =~ "Changes data."
    assert CodeMode.docs(name: "list_items", tools: @tools) =~ "Changes data."

    both = CodeMode.docs(names: ["echo", "fails"], tools: @tools)
    assert both =~ "# echo" and both =~ "# fails"

    assert CodeMode.docs(search: "sums", tools: @tools) =~ "sum_list"
    assert CodeMode.docs(search: "qqqq", tools: @tools) =~ "Nothing matches"

    unknown = CodeMode.docs(name: "list_item", tools: @tools)
    assert unknown =~ "No function called"
    assert unknown =~ "list_items"
  end

  test "default docs index uses the catalog groups" do
    assert is_binary(CodeMode.docs())
  end

  test "render value, prints, errors" do
    r = run(~s|print("hello")\nreturn { a = 1 }|)
    out = CodeMode.render(r)
    assert out =~ ~s|"a": 1|
    assert out =~ "hello"

    out = CodeMode.render(run(~s|print("p")\nerror("bad")|))
    assert out =~ "runtime: "
    assert out =~ "p"
  end

  test "render caps long answers and keeps valid UTF-8" do
    r = %CodeMode.Result{value: String.duplicate("é", 40_000)}
    out = CodeMode.render(r)
    assert byte_size(out) <= CodeMode.max_answer_bytes()
    assert String.valid?(out)
    assert out =~ "truncated"

    bad = %CodeMode.Result{value: nil, prints: [<<0xFF, "ok">>]}
    assert String.valid?(CodeMode.render(bad))
  end
end
