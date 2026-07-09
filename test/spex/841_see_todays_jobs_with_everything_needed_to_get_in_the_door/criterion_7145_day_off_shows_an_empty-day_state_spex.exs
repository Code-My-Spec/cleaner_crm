defmodule CleanerCrmSpex.Story841.Criterion7145Spex do
  @moduledoc """
  Story 841 — See today's jobs with everything needed to get in the door
  Criterion 7145 — A cleaner with no jobs scheduled for the selected day
  sees an explicit empty-day state rather than a blank screen.
  """

  use CleanerCrmSpex.Case

  alias CleanerCrmSpex.Fixtures

  spex "a day with no jobs shows an empty-day state" do
    scenario "day off shows an empty-day state" do
      given_ "the owner is logged in with an active account", context do
        user = Fixtures.user_fixture()
        scope = Fixtures.user_scope_fixture(user)
        account = Fixtures.account_fixture(scope)
        conn = Fixtures.log_in_user(context.conn, user)

        {:ok, Map.merge(context, %{conn: conn, user: user, scope: scope, account: account})}
      end

      given_ "I am a cleaner signed in on my phone", context do
        cleaner =
          Fixtures.cleaner_fixture(context.scope, context.account, %{
            email: "cleaner-#{System.unique_integer([:positive])}@example.com"
          })

        cleaner_conn = Fixtures.log_in_user(Phoenix.ConnTest.build_conn(), cleaner)

        {:ok, Map.merge(context, %{cleaner: cleaner, cleaner_conn: cleaner_conn})}
      end

      given_ "I have no jobs scheduled for today", context do
        {:ok, context}
      end

      when_ "I open the day view", context do
        {:ok, today_live, html} = live(context.cleaner_conn, ~p"/field")

        {:ok, Map.merge(context, %{today_live: today_live, html: html})}
      end

      then_ "I see a message telling me I have no jobs today", context do
        assert has_element?(context.today_live, "[data-test='empty-day-state']")

        {:ok, context}
      end

      then_ "I am not shown a blank or broken screen", context do
        assert has_element?(context.today_live, "[data-test='field-today']")
        assert Regex.scan(~r/data-test="job-card"/, context.html) == []

        {:ok, context}
      end
    end
  end
end
