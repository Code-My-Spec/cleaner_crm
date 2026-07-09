defmodule CleanerCrmWeb.BookingLive.AcceptTest do
  @moduledoc """
  Covers issue 4e985412: the `/book/accept/:token` slot-selection form
  accepted any date, including years in the past, with zero
  validation — QA drove `scheduled_date=2020-01-01` through card
  capture and it converted into a real scheduled job. No spex/BDD
  story owns this surface, so it's covered here instead. See also
  `CleanerCrm.BookingTest` for the context-level (`Booking`/`Lead`)
  coverage, including the defense-in-depth re-check at confirmation.
  """

  use CleanerCrmTest.ConnCase, async: true

  import Phoenix.LiveViewTest
  import CleanerCrm.UsersFixtures

  alias CleanerCrm.Accounts
  alias CleanerCrm.Booking
  alias CleanerCrm.Users.Scope

  defp scope_fixture do
    user = user_fixture()
    scope = Scope.for_user(user)

    {:ok, account} =
      Accounts.create_account(scope, %{name: "Sparkle Co #{System.unique_integer([:positive])}"})

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
          status: :accepted,
          client_name: "Dana Prescott",
          client_email: "dana-#{System.unique_integer([:positive])}@example.com",
          client_phone: "+15555550100"
        })
      )

    lead
  end

  test "a past scheduled date is rejected with a clear error and never reaches the confirm step",
       %{conn: conn} do
    scope = scope_fixture()
    lead = lead_fixture(scope)

    {:ok, accept_live, _html} = live(conn, ~p"/book/accept/#{lead.acceptance_token}")

    html =
      accept_live
      |> form("[data-test='slot-form']",
        booking: %{scheduled_date: "2020-01-01", start_time: "09:00"}
      )
      |> render_submit()

    assert html =~ "must be today or later"
    assert has_element?(accept_live, "[data-test='slot-form']")
    refute has_element?(accept_live, "[data-test='confirmation-form']")

    reloaded = Booking.get_lead_by_token(lead.acceptance_token)
    assert reloaded.scheduled_date == nil
  end

  test "a valid future date advances to the confirmation step", %{conn: conn} do
    scope = scope_fixture()
    lead = lead_fixture(scope)

    {:ok, accept_live, _html} = live(conn, ~p"/book/accept/#{lead.acceptance_token}")

    accept_live
    |> form("[data-test='slot-form']",
      booking: %{
        scheduled_date: Date.to_iso8601(Date.add(Date.utc_today(), 10)),
        start_time: "09:00"
      }
    )
    |> render_submit()

    assert has_element?(accept_live, "[data-test='confirmation-form']")
  end
end
