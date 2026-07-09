defmodule CleanerCrm.JourneyFixtures do
  @moduledoc """
  Shared prerequisite setup for `test/journeys/` feature tests: an
  owner and a cleaner, both with a known password, sharing one
  account — the minimum every journey needs before it can log in
  through the browser and drive the rest of the flow for real.
  """

  import CleanerCrm.UsersFixtures
  import Wallaby.Browser

  alias CleanerCrm.Accounts
  alias CleanerCrm.Users.Scope

  @doc """
  Returns `%{owner:, cleaner:, account:, owner_scope:, password:}`.

  `owner` and `cleaner` both have `password` set (from
  `valid_user_password/0`) so a Wallaby session can log in as either
  through the real `/users/log-in` form.
  """
  def account_with_owner_and_cleaner(attrs \\ %{}) do
    owner = user_fixture() |> set_password()
    owner_scope = Scope.for_user(owner)

    {:ok, account} =
      Accounts.create_account(
        owner_scope,
        Enum.into(attrs, %{name: "Journey QA Co #{System.unique_integer([:positive])}"})
      )

    owner_scope = %{owner_scope | active_account: account, active_account_id: account.id}

    cleaner = user_fixture() |> set_password()
    {:ok, _member} = Accounts.add_user_to_account(owner_scope, cleaner.id, account.id, :member)

    %{
      owner: owner,
      cleaner: cleaner,
      account: account,
      owner_scope: owner_scope,
      password: valid_user_password()
    }
  end

  @doc """
  Logs the given user into the Wallaby `session` via the real password
  form. Each actor in a multi-actor journey test should get their own
  session (via `@sessions N` / `%{sessions: [...]}`) rather than
  logging out and back in on one session — Wallaby has no cookie-clear
  helper, and juggling one session between actors doesn't match how
  two real people would use the app at once anyway.

  Two timing quirks, both confirmed by repeated runs, not guesses:

  - The magic-link form's email input carries `phx-mounted={JS.focus()}`
    (autofocus on connect). If the password form's email field is
    filled before that hook fires, the steal-focus race sometimes
    empties it back out mid-keystroke — so this waits a beat after
    `visit` before touching either field.
  - The password form submits over the LiveView socket first, which
    just flips `phx-trigger-action` to make the JS client re-submit it
    a second time as a real native POST (the only way to actually
    write the session cookie) — so this waits for something that only
    exists after that second, real submission lands, not just for the
    click's own socket round-trip.
  """
  def log_in(session, user, password) do
    import Wallaby.Query

    session = visit(session, "/users/log-in")
    Process.sleep(500)

    session
    |> fill_in(css("#login_form_password_email"), with: user.email)
    |> fill_in(css("#user_password"), with: password)
    |> click(button("Log in only this time"))
    |> assert_has(link("Log out"))
  end

  @doc """
  `visit/2` followed by `settle/2` — see `settle/2` for why every
  fresh mount in this app needs a beat before the next interaction.
  """
  def visit!(session, path, ms \\ 1000) do
    session |> visit(path) |> settle(ms)
  end

  @doc """
  Sets a form field's value via JS (`.value =` + a real `input`/
  `change` event dispatch) rather than `fill_in`/label-text queries.
  Two reasons, both confirmed by repeated runs during Journey 1, not
  guesses: this app's `<label for=id><span>Label</span><input
  .../></label>` markup isn't one Wallaby's label-lookup resolves, and
  native `<input type="date">`/`<input type="time">` widgets don't
  reliably accept `send_keys` text across browsers regardless.
  """
  def set_field(session, css_selector, value) do
    execute_script(
      session,
      """
      var el = document.querySelector(arguments[0]);
      el.value = arguments[1];
      el.dispatchEvent(new Event('input', {bubbles: true}));
      el.dispatchEvent(new Event('change', {bubbles: true}));
      """,
      [css_selector, value]
    )
  end

  @doc "Checks a checkbox via JS — see `set_field/3`; same rationale."
  def check_field(session, css_selector) do
    execute_script(
      session,
      """
      var el = document.querySelector(arguments[0]);
      el.checked = true;
      el.dispatchEvent(new Event('input', {bubbles: true}));
      el.dispatchEvent(new Event('change', {bubbles: true}));
      """,
      [css_selector]
    )
  end

  @doc """
  A deliberate pause after a click that saves/submits/navigates, or
  after a fresh `visit`. `assert_has`'s own retry (default 3s) doesn't
  reliably cover either gap in this environment — confirmed by
  repeated runs across every journey, not a guess: without it, clicks
  and field fills intermittently land on a not-yet-settled DOM (a
  save's redirect not yet landed, or a sibling autofocus hook still
  racing for the field being filled).
  """
  def settle(session, ms \\ 1000) do
    Process.sleep(ms)
    session
  end
end
