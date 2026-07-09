# Mix.Tasks.CmsGen.Integrations

Generates the integrations context with OAuth flow support,
encrypted token storage, and provider behaviour.

    $ mix cms_gen.integrations

This generator requires `phx.gen.auth` to have been run first.

## Generated files

  * `lib/app/integrations/integration.ex` — Integration schema
  * `lib/app/integrations/integration_repository.ex` — Data access with upsert
  * `lib/app/integrations/o_auth_state_store.ex` — ETS-backed OAuth state
  * `lib/app/integrations/providers/behaviour.ex` — Provider behaviour
  * `lib/app/integrations.ex` — Integrations context
  * `lib/app/encrypted/binary.ex` — Cloak.Ecto encrypted type
  * `lib/app/vault.ex` — Cloak vault
  * `lib/app_web/controllers/integrations_controller.ex` — OAuth controller
  * `lib/app_web/live/integration_live/index.ex` — Integrations listing
  * `priv/repo/migrations/*_create_integrations_tables.exs` — Migration

## Dependencies

You will need to add the following dependencies to your mix.exs:

  * `{:assent, "~> 0.3"}` — OAuth strategies
  * `{:cloak_ecto, "~> 1.3"}` — Encrypted Ecto types
  * `{:cloak, "~> 1.1"}` — Encryption vault