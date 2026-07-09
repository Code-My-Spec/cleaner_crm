defmodule CleanerCrm.Portal.PortalSessionTest do
  use CleanerCrmTest.DataCase, async: true

  alias CleanerCrm.Portal.PortalSession

  @client %{id: Ecto.UUID.generate(), account_id: Ecto.UUID.generate()}

  describe "build_changeset/2" do
    test "is valid and carries a plaintext token alongside its hash" do
      changeset = PortalSession.build_changeset(@client, %{})

      assert changeset.valid?
      assert token = get_change(changeset, :token)
      assert is_binary(token)
      assert get_change(changeset, :token_hash) == PortalSession.hash_token(token)
    end

    test "scopes the session to the given client and account" do
      changeset = PortalSession.build_changeset(@client, %{})

      assert changeset.data.client_id == @client.id
      assert changeset.data.account_id == @client.account_id
    end

    test "defaults expires_at several days out when not given" do
      changeset = PortalSession.build_changeset(@client, %{})

      assert %DateTime{} = expires_at = get_change(changeset, :expires_at)
      assert DateTime.compare(expires_at, DateTime.utc_now()) == :gt
    end

    test "honors an explicit expires_at override" do
      expires_at = DateTime.add(DateTime.utc_now(), -3600, :second)
      changeset = PortalSession.build_changeset(@client, %{expires_at: expires_at})

      assert get_change(changeset, :expires_at) == expires_at
    end
  end

  describe "hash_token/1" do
    test "is deterministic for the same input" do
      assert PortalSession.hash_token("abc") == PortalSession.hash_token("abc")
    end

    test "differs for different inputs" do
      refute PortalSession.hash_token("abc") == PortalSession.hash_token("xyz")
    end
  end

  describe "expired?/1" do
    test "false for a session expiring in the future" do
      session = %PortalSession{expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)}
      refute PortalSession.expired?(session)
    end

    test "true for a session that already expired" do
      session = %PortalSession{expires_at: DateTime.add(DateTime.utc_now(), -3600, :second)}
      assert PortalSession.expired?(session)
    end
  end

  describe "touch_changeset/1" do
    test "stamps last_used_at to now" do
      changeset = PortalSession.touch_changeset(%PortalSession{})

      assert %DateTime{} = last_used_at = get_change(changeset, :last_used_at)
      assert DateTime.diff(DateTime.utc_now(), last_used_at, :second) < 5
    end
  end
end
