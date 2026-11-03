defmodule CleanerCrmMcp.Tools.ImportsTest do
  use CleanerCrmTest.DataCase, async: false

  alias CleanerCrmMcp.Tools.Imports.{FindImported, ListImports}
  alias Mix.Tasks.Crm.ImportMaidilyTest, as: Fixtures

  setup do
    dir = Fixtures.write_fixtures!()

    result =
      Mix.Tasks.Crm.ImportMaidily.run_import(dir,
        account: "Tools Co",
        owner_email: "tools@example.test"
      )

    %{scope: result.scope}
  end

  test "group lists both tools" do
    assert CleanerCrmMcp.Tools.Imports.tools() == [FindImported, ListImports]
  end

  test "find_imported by source_ref returns the job number and a summary", %{scope: scope} do
    assert {:ok, [match]} = FindImported.call(%{"kind" => "job", "source_ref" => "INV-3"}, scope)
    assert match["job_number"] in 1001..1004
    assert match["source_id"] == "102"
    assert match["summary"]["status"] == "in_progress"
    refute Map.has_key?(match["summary"], "email")
  end

  test "find_imported by source_id and for no match", %{scope: scope} do
    assert {:ok, [%{"crm_id" => id}]} =
             FindImported.call(%{"kind" => "client", "source_id" => "1"}, scope)

    assert is_binary(id)
    assert {:ok, []} = FindImported.call(%{"kind" => "client", "source_id" => "999"}, scope)
    assert {:error, _} = FindImported.call(%{"kind" => "client"}, scope)
  end

  test "list_imports filters by kind and limit", %{scope: scope} do
    assert {:ok, rows} = ListImports.call(%{"kind" => "job"}, scope)
    assert length(rows) == 4
    assert Enum.all?(rows, &(&1["kind"] == "job" and is_integer(&1["job_number"])))
    assert {:ok, [_]} = ListImports.call(%{"limit" => 1}, scope)
  end
end
