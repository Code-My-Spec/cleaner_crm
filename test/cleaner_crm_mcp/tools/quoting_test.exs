defmodule CleanerCrmMcp.Tools.QuotingTest do
  use CleanerCrmTest.DataCase, async: true

  import CleanerCrm.UsersFixtures

  alias CleanerCrm.{Accounts, Clients, Quoting}
  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.Catalog

  alias CleanerCrmMcp.Tools.Quoting.{
    CreateQuote,
    EstimatePrice,
    GetQuote,
    GetRateCard,
    ListQuotes,
    UpdateRateCard
  }

  defp scope_fixture(name) do
    owner_scope = Scope.for_user(user_fixture())
    {:ok, account} = Accounts.create_account(owner_scope, %{name: name})
    %{owner_scope | active_account_id: account.id, active_account: account}
  end

  setup do
    scope = scope_fixture("Sparkle")
    other = scope_fixture("Other Co")

    {:ok, rc} =
      Quoting.update_rate_card(scope, Quoting.get_or_create_rate_card(scope), %{
        per_room_bedroom_rate_cents: 3000,
        per_room_bathroom_rate_cents: 2000,
        weekly_discount_percent: 10,
        add_on_rates_cents: %{"inside_fridge" => 1500}
      })

    %{scope: scope, other: other, rate_card: rc}
  end

  test "tool names are unique and every tool is registered in the catalog" do
    for tool <- CleanerCrmMcp.Tools.Quoting.tools() do
      assert {:ok, ^tool} = Catalog.fetch(tool.name())
      assert tool.description() =~ ~r/\S/
    end
  end

  describe "estimate_price" do
    test "prices rooms, add-ons and frequency discount", %{scope: scope} do
      {:ok, args} =
        Catalog.coerce(EstimatePrice, %{
          "bedrooms" => 3,
          "bathrooms" => 2,
          "frequency" => "weekly",
          "add_ons" => %{1 => "inside_fridge"}
        })

      assert {:ok, p} = EstimatePrice.call(args, scope)
      # 3*3000 + 2*2000 + 1500 = 14500, minus 10%
      assert p["subtotal_cents"] == 14_500
      assert p["total_cents"] == 13_050
      assert p["total"] == 130.5
      assert p["priceable"]
      refute p["minimum_applied"]
    end

    test "flags unpriced models and rejects bad input", %{scope: scope} do
      assert {:ok, %{"priceable" => false}} = EstimatePrice.call(%{"hours" => 2}, scope)
      assert {:error, _} = EstimatePrice.call(%{}, scope)

      assert {:error, "frequency" <> _} =
               EstimatePrice.call(%{"hours" => 2, "frequency" => "daily"}, scope)

      assert {:error, msg} = Catalog.coerce(EstimatePrice, %{"bedroom" => 2})
      assert msg =~ "unknown argument"
    end
  end

  describe "create_quote / get_quote / list_quotes" do
    test "saves a priced quote and reads it back", %{scope: scope} do
      {:ok, client} = Clients.create_client(scope, %{name: "Dana"})

      assert {:ok, q} =
               CreateQuote.call(
                 %{"bedrooms" => 2, "bathrooms" => 1, "client_id" => client.id},
                 scope
               )

      assert q["total_cents"] == 8000
      assert q["status"] == "sent"
      assert length(q["items"]) == 2

      assert {:ok, ^q} = GetQuote.call(%{"id" => q["id"]}, scope)

      assert {:ok, [summary]} =
               ListQuotes.call(%{"status" => "sent", "client_id" => client.id}, scope)

      assert summary["id"] == q["id"]
      assert {:ok, []} = ListQuotes.call(%{"status" => "draft"}, scope)
      assert {:error, _} = ListQuotes.call(%{"status" => "weird"}, scope)
    end

    test "errors when a rate is missing", %{scope: scope} do
      assert {:error, msg} = CreateQuote.call(%{"hours" => 3, "client_name" => "X"}, scope)
      assert msg =~ "cannot price"
    end

    test "quotes are isolated per account", %{scope: scope, other: other} do
      {:ok, q} = CreateQuote.call(%{"bedrooms" => 1, "client_name" => "Dana"}, scope)
      assert {:error, "no quote" <> _} = GetQuote.call(%{"id" => q["id"]}, other)
      assert {:ok, []} = ListQuotes.call(%{}, other)
      assert {:error, "no quote" <> _} = GetQuote.call(%{"id" => "not-a-uuid"}, scope)
    end
  end

  describe "rate card" do
    test "get presents money in cents and dollars", %{scope: scope} do
      assert {:ok, rc} = GetRateCard.call(%{}, scope)
      assert rc["bedroom_rate_cents"] == 3000
      assert rc["bedroom_rate"] == 30.0
      assert rc["hourly_rate_cents"] == nil
      assert rc["add_on_rates"]["inside_fridge"]["cents"] == 1500
    end

    test "update converts dollars, merges add-ons, and is account-scoped", %{
      scope: scope,
      other: other
    } do
      assert {:ok, rc} =
               UpdateRateCard.call(
                 %{"hourly_rate" => 45.5, "add_on_rates" => %{"oven" => 25}},
                 scope
               )

      assert rc["hourly_rate_cents"] == 4550
      assert rc["bedroom_rate_cents"] == 3000
      assert Map.keys(rc["add_on_rates"]) |> Enum.sort() == ["inside_fridge", "oven"]

      assert {:ok, other_rc} = GetRateCard.call(%{}, other)
      assert other_rc["hourly_rate_cents"] == nil
    end

    test "update surfaces validation errors", %{scope: scope} do
      assert {:error, %Ecto.Changeset{}} =
               UpdateRateCard.call(%{"weekly_discount_percent" => 150}, scope)
    end
  end
end
