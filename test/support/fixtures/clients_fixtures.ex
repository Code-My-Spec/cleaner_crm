defmodule CleanerCrm.ClientsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `CleanerCrm.Clients` context.
  """

  alias CleanerCrm.Clients

  def client_fixture(scope, attrs \\ %{}) do
    {:ok, client} =
      attrs
      |> Enum.into(%{name: "Client #{System.unique_integer([:positive])}"})
      |> then(&Clients.create_client(scope, &1))

    client
  end

  def property_fixture(scope, %Clients.Client{} = client, attrs \\ %{}) do
    {:ok, property} =
      attrs
      |> Enum.into(%{
        client_id: client.id,
        service_address: "123 Oak St #{System.unique_integer([:positive])}"
      })
      |> then(&Clients.create_property(scope, &1))

    property
  end
end
