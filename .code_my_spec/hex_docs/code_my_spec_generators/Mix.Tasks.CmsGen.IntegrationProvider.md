# Mix.Tasks.CmsGen.IntegrationProvider

Generates an OAuth provider module for the integrations system.

    $ mix cms_gen.integration_provider GitHub github
    $ mix cms_gen.integration_provider Google google
    $ mix cms_gen.integration_provider Facebook facebook
    $ mix cms_gen.integration_provider QuickBooks quickbooks

The first argument is the human-readable provider name (e.g., "GitHub").
The second argument is the provider atom key (e.g., "github").

This generator requires `cms_gen.integrations` to have been run first.

## Generated files

  * `lib/app/integrations/providers/<provider>.ex` — Provider module

## Known providers

For GitHub, Google, Facebook, and QuickBooks, specialized templates
are used with pre-configured OAuth scopes and endpoints. For unknown
providers, a generic template is generated.