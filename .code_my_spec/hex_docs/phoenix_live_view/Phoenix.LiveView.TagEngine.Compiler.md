# Phoenix.LiveView.TagEngine.Compiler



## compile/2

Compiles the node tag tree into Elixir code.

Under the hood, this uses the `Phoenix.LiveView.Engine`
to convert template parts into static and dynamic parts
and perform change tracking. See the Engine documentation
for more details.

This function is responsible for converting the nodes into
text and expression parts and properly invoking the engine
with the correct code for features like components and slots.