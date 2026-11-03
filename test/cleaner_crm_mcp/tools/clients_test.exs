defmodule CleanerCrmMcp.Tools.ClientsTest do
  use CleanerCrmTest.DataCase, async: true

  import CleanerCrm.UsersFixtures
  import CleanerCrm.ClientsFixtures
  import CleanerCrm.SchedulingFixtures

  alias CleanerCrm.{Accounts, Booking, Clients}
  alias CleanerCrm.Users.Scope
  alias CleanerCrmMcp.Catalog
  alias CleanerCrmMcp.Tools.Clients, as: T

  defp scope_fixture do
    scope = Scope.for_user(user_fixture())

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Co #{System.unique_integer([:positive])}"})

    %{scope | active_account: account, active_account_id: account.id}
  end

  defp lead_fixture(scope, attrs \\ %{}) do
    {:ok, lead} =
      Booking.create_lead(
        scope,
        Enum.into(attrs, %{
          pricing_model: :per_room,
          bedroom_count: 3,
          bathroom_count: 2,
          frequency: :one_time,
          total_cents: 19_500,
          client_name: "Dana Prescott",
          client_email: "dana@example.com",
          client_phone: "+15555550100"
        })
      )

    lead
  end

  defp call!(tool, raw, scope) do
    {:ok, args} = Catalog.coerce(tool, raw)
    tool.call(args, scope)
  end

  @secret_lockbox "LB-7731"
  @secret_alarm "AL-9942"

  defp secret_property(scope) do
    client =
      client_fixture(scope, %{
        name: "Sam Rivera",
        phone: "(928) 598-4841",
        email: "sam@example.com"
      })

    property =
      property_fixture(scope, client, %{
        lockbox_code: @secret_lockbox,
        alarm_code: @secret_alarm,
        entry_method: "lockbox"
      })

    {client, property}
  end

  test "all tools are registered, valid and uniquely named" do
    tools = T.tools()
    assert length(tools) == length(Enum.uniq_by(tools, & &1.name()))

    for t <- tools do
      assert t.description() =~ ~r/\S/

      assert Enum.all?(
               t.params(),
               &(is_binary(&1.name) and &1.type in [:string, :integer, :boolean])
             )
    end

    assert T.GetPropertyAccess.description() =~ "SECRETS"
  end

  describe "search_clients" do
    test "matches phone in any format, name and email; filters active; scopes account" do
      scope = scope_fixture()
      {client, _} = secret_property(scope)
      other = scope_fixture()
      client_fixture(other, %{name: "Sam Rivera", phone: "9285984841"})

      for q <- [
            "(928) 598-4841",
            "9285984841",
            "+19285984841",
            "598-4841",
            "sam riv",
            "SAM@EXAMPLE"
          ] do
        assert {:ok, [%{"id" => id}]} = call!(T.SearchClients, %{"query" => q}, scope)
        assert id == client.id
      end

      assert {:ok, []} = call!(T.SearchClients, %{"query" => "nobody"}, scope)
      assert {:ok, []} = call!(T.SearchClients, %{"query" => "Sam", "active" => false}, scope)
      assert {:ok, [_]} = call!(T.SearchClients, %{"query" => "Sam", "active" => true}, scope)
      assert {:ok, [_]} = call!(T.SearchClients, %{}, scope)
    end

    test "treats % and _ literally" do
      scope = scope_fixture()
      client_fixture(scope, %{name: "Abc"})
      assert {:ok, []} = call!(T.SearchClients, %{"query" => "%"}, scope)
    end
  end

  describe "clients" do
    test "create, update, deactivate, get" do
      scope = scope_fixture()

      assert {:ok, %{"id" => id, "active" => true}} =
               call!(T.CreateClient, %{"name" => "Pat", "preferred_channel" => "sms"}, scope)

      assert {:ok, %{"preferred_channel" => "sms"}} = call!(T.GetClient, %{"id" => id}, scope)

      assert {:ok, %{"phone" => "555"}} =
               call!(T.UpdateClient, %{"id" => id, "phone" => "555"}, scope)

      assert {:ok, %{"active" => false}} = call!(T.DeactivateClient, %{"id" => id}, scope)
      assert {:error, %Ecto.Changeset{}} = call!(T.CreateClient, %{"name" => ""}, scope)
    end

    test "get_client includes properties and job summary" do
      scope = scope_fixture()
      {client, property} = secret_property(scope)
      job_fixture(scope, property, %{client_id: client.id})

      assert {:ok, result} = call!(T.GetClient, %{"id" => client.id}, scope)
      assert [%{"id" => pid}] = result["properties"]
      assert pid == property.id
      assert length(result["upcoming_jobs"]) + length(result["recent_jobs"]) == 1
    end

    test "other accounts' clients are not found" do
      scope = scope_fixture()
      other = client_fixture(scope_fixture())

      for tool <- [T.GetClient, T.UpdateClient, T.DeactivateClient] do
        assert {:error, "client not found"} = call!(tool, %{"id" => other.id}, scope)
      end

      assert {:error, "client not found"} =
               call!(T.ListProperties, %{"client_id" => other.id}, scope)

      assert {:error, "client not found"} =
               call!(
                 T.CreateProperty,
                 %{"client_id" => other.id, "service_address" => "x"},
                 scope
               )

      assert {:error, "client not found"} = call!(T.GetClient, %{"id" => "not-a-uuid"}, scope)
    end
  end

  describe "properties and access codes" do
    test "only get_property_access reveals codes" do
      scope = scope_fixture()
      {client, property} = secret_property(scope)

      outputs = [
        call!(T.GetProperty, %{"id" => property.id}, scope),
        call!(T.ListProperties, %{"client_id" => client.id}, scope),
        call!(T.GetClient, %{"id" => client.id}, scope),
        call!(T.UpdateProperty, %{"id" => property.id, "pet_notes" => "cat"}, scope),
        call!(
          T.UpdatePropertyAccess,
          %{"property_id" => property.id, "alarm_code" => "NEW-1111"},
          scope
        ),
        call!(T.CreateProperty, %{"client_id" => client.id, "service_address" => "9 Elm"}, scope),
        call!(T.SearchClients, %{"query" => "Sam"}, scope)
      ]

      for out <- outputs do
        text = inspect(out)
        refute text =~ @secret_lockbox
        refute text =~ @secret_alarm
        refute text =~ "NEW-1111"
        refute text =~ ~r/"(lockbox|alarm)_code" =>/
      end

      assert {:ok, %{"has_lockbox_code" => true}} =
               call!(T.GetProperty, %{"id" => property.id}, scope)

      assert {:ok, %{"lockbox_code" => @secret_lockbox, "alarm_code" => "NEW-1111"}} =
               call!(T.GetPropertyAccess, %{"property_id" => property.id}, scope)
    end

    test "update_property_access persists encrypted-readable codes" do
      scope = scope_fixture()
      {_, property} = secret_property(scope)

      assert {:ok, _} =
               call!(
                 T.UpdatePropertyAccess,
                 %{"property_id" => property.id, "lockbox_code" => "0001"},
                 scope
               )

      assert Clients.get_property!(scope, property.id).lockbox_code == "0001"
    end

    test "create/update property" do
      scope = scope_fixture()
      client = client_fixture(scope)

      assert {:ok, %{"id" => id, "pet_notes" => "dog"}} =
               call!(
                 T.CreateProperty,
                 %{"client_id" => client.id, "service_address" => "1 A St", "pet_notes" => "dog"},
                 scope
               )

      assert {:ok, %{"parking_notes" => "drive"}} =
               call!(T.UpdateProperty, %{"id" => id, "parking_notes" => "drive"}, scope)

      assert {:error, %Ecto.Changeset{}} =
               call!(
                 T.CreateProperty,
                 %{"client_id" => client.id, "service_address" => ""},
                 scope
               )
    end

    test "other accounts' properties are not found" do
      scope = scope_fixture()
      {_, foreign} = secret_property(scope_fixture())

      assert {:error, "property not found"} = call!(T.GetProperty, %{"id" => foreign.id}, scope)

      assert {:error, "property not found"} =
               call!(T.GetPropertyAccess, %{"property_id" => foreign.id}, scope)

      assert {:error, "property not found"} =
               call!(T.UpdateProperty, %{"id" => foreign.id}, scope)

      assert {:error, "property not found"} =
               call!(T.UpdatePropertyAccess, %{"property_id" => foreign.id}, scope)
    end

    test "coerce rejects missing and unknown args" do
      assert {:error, msg} = Catalog.coerce(T.GetPropertyAccess, %{})
      assert msg =~ "property_id"
      assert {:error, _} = Catalog.coerce(T.GetProperty, %{"id" => "x", "bogus" => 1})
    end
  end

  describe "leads" do
    test "list and get, filtered by status, account-scoped" do
      scope = scope_fixture()
      lead = lead_fixture(scope)
      lead_fixture(scope_fixture())

      assert {:ok, [%{"id" => id, "total" => 195.0, "total_cents" => 19_500}]} =
               call!(T.ListLeads, %{}, scope)

      assert id == lead.id
      assert {:ok, [_]} = call!(T.ListLeads, %{"status" => "accepted"}, scope)
      assert {:ok, []} = call!(T.ListLeads, %{"status" => "converted"}, scope)
      assert {:error, _} = call!(T.ListLeads, %{"status" => "bogus"}, scope)

      assert {:ok, %{"client_name" => "Dana Prescott", "status" => "accepted"} = out} =
               call!(T.GetLead, %{"id" => lead.id}, scope)

      refute Map.has_key?(out, "acceptance_token")
      assert {:error, "lead not found"} = call!(T.GetLead, %{"id" => lead.id}, scope_fixture())
    end
  end
end
