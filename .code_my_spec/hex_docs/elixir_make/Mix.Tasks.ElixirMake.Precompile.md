# Mix.Tasks.ElixirMake.Precompile

Precompiles the given project for all targets.

This task must only be used by package creators who want to ship the
precompiled NIFs. This task is often used on CI to precompile
for different targets.

This is only supported if `:make_precompiler` is specified
in your project configuration.