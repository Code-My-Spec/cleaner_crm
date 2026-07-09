# Mix.Tasks.Phx.Gen.Socket

Generates a Phoenix socket handler.

    $ mix phx.gen.socket User

Accepts the module name for the socket.

The generated files will contain:

For a regular application:

  * a client in `assets/js`
  * a socket in `lib/my_app_web/channels`

For an umbrella application:

  * a client in `apps/my_app_web/assets/js`
  * a socket in `apps/my_app_web/lib/my_app_web/channels`

You can then generate channels with `mix phx.gen.channel`.