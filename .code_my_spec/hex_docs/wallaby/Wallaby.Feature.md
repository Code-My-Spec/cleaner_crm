# Wallaby.Feature

Helpers for writing features.

You can `use` or `import` this module.

## use Wallaby.Feature

Calling this module with `use` will automatically call `use Wallaby.DSL`.

When called with `use` and you are using Ecto, please configure your `otp_app`.

```
config :wallaby, otp_app: :your_app
```

## feature/3

Defines a feature with a message.

Adding `import Wallaby.Feature` to your test module will import the `Wallaby.Feature.feature/3` macro. This is a drop in replacement for the `ExUnit.Case.test/3` macro that you normally use.

Adding `use Wallaby.Feature` to your test module will act the same as `import Wallaby.Feature`, as well as configure your Ecto repos properly and pass a `Wallaby.Session` into the test context.

## Sessions

When called with `use`, the `Wallaby.Feature.feature/3` macro will automatically start a single session using the currently configured capabilities and is passed to the feature via the `:session` key in the context.

```
feature "test with a single session", %{session: session} do
  # ...
end
```

If you would like to start multiple sessions, assign the `@sessions` attribute to the number of sessions that the feature should start, and they will be pass to the feature via the `:sessions` key in the context.

```
@sessions 2
feature "test with a two sessions", %{sessions: [session_1, sessions_2]} do
  # ...
end
```

If you need to change the headless mode, binary path, or capabilities sent to the session for a specific feature, you can assign `@sessions` to a list of keyword lists of the options to be passed to `Wallaby.start_session/1`. This will start the number of sessions equal to the size of the list.

```
@sessions [
  [headless: false, binary: "some_path", capabilities: %{}]
]
feature "test with different capabilities", %{session: session} do
  # ...
end
```

If you don't wish to `use Wallaby.Feature` in your test module, you can add the following code to configure Ecto and create a session.

```
setup tags do
  :ok = Ecto.Adapters.SQL.Sandbox.checkout(YourApp.Repo)

  unless tags[:async] do
    Ecto.Adapters.SQL.Sandbox.mode(YourApp.Repo, {:shared, self()})
  end

  metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(YourApp.Repo, self())
  {:ok, session} = Wallaby.start_session(metadata: metadata)

  {:ok, session: session}
end
```

## Screenshots

If you have configured `screenshot_on_failure` to be true, any exceptions raised during the feature will trigger a screenshot to be taken.