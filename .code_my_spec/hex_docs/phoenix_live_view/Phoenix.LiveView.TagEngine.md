# Phoenix.LiveView.TagEngine

Building blocks for tag based `Phoenix.Template.Engine`s.

This cannot be directly used by Phoenix applications.
Instead, it is the building block for engines such as
`Phoenix.LiveView.HTMLEngine`.

It is typically invoked like this:

    Phoenix.LiveView.TagEngine.compile(source,
      line: 1,
      file: path,
      caller: __CALLER__,
      source: source,
      tag_handler: FooBarEngine
    )

Where `:tag_handler` implements the behaviour defined by this module.

## compile/2

Compiles the given string into Elixir AST.

The accepted options are:

  * `tag_handler` - Required. The module implementing the `Phoenix.LiveView.TagEngine` behavior.
  * `caller` - Required. The `Macro.Env`.
  * `line` - the starting line offset. Defaults to 1.
  * `file` - the file of the template. Defaults to `"nofile"`.
  * `indentation` - the indentation of the template. Defaults to 0.

## component/3

Renders a component defined by the given function.

This function is rarely invoked directly by users. Instead, it is used by `~H`
and other engine implementations to render `Phoenix.Component`s. For example,
the following:

```heex
<MyApp.Weather.city name="Kraków" />
```

Is the same as:

```heex
<%= component(
      &MyApp.Weather.city/1,
      [name: "Kraków"],
      {__ENV__.module, __ENV__.function, __ENV__.file, __ENV__.line}
    ) %>
```

## inner_block/2

Define an inner block, generally used by slots.

This macro is mostly used by custom HTML engines that provide
a `slot` implementation and rarely called directly. The
`name` must be the assign name the slot/block will be stored
under.

If you're using HEEx templates, you should use its higher
level `<:slot>` notation instead. See `Phoenix.Component`
for more information.