# Mix.Tasks.Phx.Gen.Presence

Generates a Presence tracker.

    $ mix phx.gen.presence
    $ mix phx.gen.presence MyPresence

The argument, which defaults to `Presence`, defines the module name of the
Presence tracker.

Generates a new file, `lib/my_app_web/channels/my_presence.ex`, where
`my_presence` is the snake-cased version of the provided module name.