# Mix.Tasks.Compile.PhoenixLiveView

A LiveView compiler for HEEx macro components.

Right now, only `Phoenix.LiveView.ColocatedHook`, `Phoenix.LiveView.ColocatedJS`,
and `Phoenix.LiveView.ColocatedCSS` are handled.

You must add it to your `mix.exs` as:

    compilers: [:phoenix_live_view] ++ Mix.compilers()