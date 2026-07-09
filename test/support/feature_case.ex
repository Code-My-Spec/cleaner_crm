defmodule CleanerCrmTest.FeatureCase do
  @moduledoc """
  Test case for Wallaby browser feature tests (`test/journeys/`).

  `use Wallaby.Feature` (via `otp_app: :cleaner_crm` in `config/test.exs`)
  handles checking out the Ecto sandbox and starting a browser session
  per test, injecting it as `session` into each `feature/3` block —
  see the Wallaby docs for the mechanics. Journey tests build their
  fixture data directly through context functions (same fixtures the
  rest of the suite uses) before driving the browser, so each test is
  a fresh, isolated thread rather than depending on dev-seeded data.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import Wallaby.Query
      import CleanerCrm.UsersFixtures
      import CleanerCrm.ClientsFixtures
      import CleanerCrm.SchedulingFixtures
      import CleanerCrm.JourneyFixtures

      alias CleanerCrm.Accounts
      alias CleanerCrm.Quality
      alias CleanerCrm.Repo
      alias CleanerCrm.Users.Scope
    end
  end
end
