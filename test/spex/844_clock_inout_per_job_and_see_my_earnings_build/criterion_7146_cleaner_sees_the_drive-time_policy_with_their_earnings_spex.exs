defmodule CleanerCrmSpex.Story844.Criterion7146Spex do
  @moduledoc """
  Story 844 — Clock in/out per job and see my earnings build
  Criterion 7146 — Cleaner sees the drive-time policy with their earnings
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "the cleaner sees the company's drive-time policy alongside their earnings" do
    scenario "cleaner sees the drive-time policy with their earnings" do
      given_ "my company's policy is that drive time between jobs is unpaid", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope, %{drive_time_policy: :unpaid})

        cleaner =
          Fixtures.cleaner_fixture(scope, account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        conn = Fixtures.log_in_user(context.conn, cleaner)

        {:ok, Map.merge(context, %{scope: scope, account: account, conn: conn})}
      end

      when_ "I view my earnings summary", context do
        {:ok, field_live, html} = live(context.conn, ~p"/app/field")

        {:ok, Map.merge(context, %{field_live: field_live, html: html})}
      end

      then_ "the drive-time policy is stated plainly", context do
        downcased = String.downcase(context.html)

        assert downcased =~ "drive time"
        assert downcased =~ "unpaid"

        {:ok, context}
      end

      then_ "I understand what is and is not counted in my pay", context do
        assert has_element?(context.field_live, "[data-test='drive-time-policy']")

        {:ok, context}
      end
    end
  end
end
