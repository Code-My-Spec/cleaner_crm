# Mix.Tasks.ClientUtils.Gen.ChatWidget

Generates an always-on support widget that connects this application's
logged-in users to CodeMySpec. One widget, two tabs:

  * **Chat** — live conversation with a CodeMySpec operator.
  * **Feedback** — report an issue (title/severity/description) with an
    optional screenshot.

    mix client_utils.gen.chat_widget

The widget is a sticky nested LiveView. Per logged-in user, the app's
**server** opens a Slipstream connection to CodeMySpec authenticated by the
project deploy key — the key never reaches the browser. Chat messages and
feedback submissions both ride that one connection; nothing uses OAuth.

## What it writes

  * `lib/<app>/code_my_spec/widget_client.ex` — per-user Slipstream client
    (relays chat messages and `submit_feedback`)
  * `lib/<app>/code_my_spec/widget.ex` — registry/supervisor interface
  * `lib/<app>_web/live/chat_widget_live.ex` — the sticky nested LiveView
    (chat + feedback tabs)

It then prints the dep, supervision, layout, and config you must add (it
does not edit those — generators leave wiring to you).

## Options

  * `--web` — the web module. Defaults to `<Base>Web`.

## Assumptions

phx.gen.auth conventions: `<Base>Web.UserAuth` provides an
`on_mount {_, :mount_current_scope}` that assigns `current_scope.user`, and
the app runs `<Base>.PubSub`. The deploy key is read from
`Application.get_env(:<app>, :deploy_key)` — the same key content sync and
`client_utils.gen.cms_users` use.