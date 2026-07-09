defmodule CleanerCrmWeb.ErrorJSONTest do
  use CleanerCrmTest.ConnCase, async: true

  test "renders 404" do
    assert CleanerCrmWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert CleanerCrmWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
