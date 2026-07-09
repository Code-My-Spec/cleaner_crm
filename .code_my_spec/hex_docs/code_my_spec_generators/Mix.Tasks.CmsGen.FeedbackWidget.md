# Mix.Tasks.CmsGen.FeedbackWidget

Generates a floating feedback widget that reports issues to CodeMySpec.

    $ mix cms_gen.feedback_widget

This generator requires `cms_gen.integrations` to have been run first.

## Generated files

  * `lib/app_web/live/feedback_widget.ex` — LiveComponent (self-contained, checks own auth)
  * `lib/app/codemyspec/client.ex` — HTTP client for CodeMySpec API
  * `assets/js/screenshot.js` — Screenshot capture via html-to-image

## How it works

The widget is a LiveComponent that checks its own connection status.
If the user hasn't connected to CodeMySpec, it renders nothing.
No on_mount hooks, no prop-drilling, no layout attr changes needed.
Just add it to Layouts.app — current_scope is already passed there.

## Prerequisites

1. Run `mix cms_gen.integrations` first
2. Run `mix cms_gen.integration_provider CodeMySpec codemyspec`