# Mix.Tasks.ClientUtils.Gen.CmsUsers

Generates a deploy-key-authenticated controller that exposes this
application's registered users to the CodeMySpec dashboard.

    mix client_utils.gen.cms_users

CodeMySpec's `ProjectUsers` context calls `GET /api/cms/users` on the
client app, authenticating with the project's deploy key, and renders the
list. This task generates the matching endpoint on the client side.

## What it writes

  * `lib/<app>_web/controllers/cms_users_controller.ex` — paginated,
    read-only, deploy-key (Bearer) authenticated. Returns `email` and
    `registered_at` per user.

It then prints the route + config you need to add (it does not edit your
router — Phoenix generators leave routing to you).

## Options

  * `--schema` — the user Ecto schema module. Defaults to
    `<Base>.Users.User`.
  * `--repo` — the Ecto repo module. Defaults to `<Base>.Repo`.
  * `--web` — the web module. Defaults to `<Base>Web`.

## Assumptions

The user schema has an `email` field and `timestamps()` (`inserted_at`).
Pass `--schema` if yours differs. The deploy key is read from
`Application.get_env(:<app>, :deploy_key)` — the same key content sync uses.