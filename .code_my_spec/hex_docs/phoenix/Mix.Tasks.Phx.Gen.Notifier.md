# Mix.Tasks.Phx.Gen.Notifier

Generates a notifier that delivers emails by default.

    $ mix phx.gen.notifier Accounts User welcome_user reset_password confirmation_instructions

This task expects a context module name, followed by a
notifier name and one or more message names. Messages
are the functions that will be created prefixed by "deliver",
so the message name should be "snake_case" without punctuation.

Additionally a context app can be specified with the flag
`--context-app`, which is useful if the notifier is being
generated in a different app under an umbrella.

    $ mix phx.gen.notifier Accounts User welcome_user --context-app marketing

The app "marketing" must exist before the command is executed.