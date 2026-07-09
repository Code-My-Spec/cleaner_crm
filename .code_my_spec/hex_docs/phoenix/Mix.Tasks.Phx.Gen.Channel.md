# Mix.Tasks.Phx.Gen.Channel

Generates a Phoenix channel.

    $ mix phx.gen.channel Room

Accepts the module name for the channel

The generated files will contain:

For a regular application:

  * a channel in `lib/my_app_web/channels`
  * a channel test in `test/my_app_web/channels`

For an umbrella application:

  * a channel in `apps/my_app_web/lib/app_name_web/channels`
  * a channel test in `apps/my_app_web/test/my_app_web/channels`