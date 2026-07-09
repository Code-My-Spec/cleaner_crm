# Phoenix.Template

Templates are markup languages that are compiled to Elixir code.

This module provides functions for loading and compiling templates
from disk. A markup language is compiled to Elixir code via an engine.
See `Phoenix.Template.Engine`.

In practice, developers rarely use `Phoenix.Template` directly. Instead,
libraries such as `Phoenix.View` and `Phoenix.LiveView` use it as a
building block.

## Custom Template Engines

Phoenix supports custom template engines. Engines tell
Phoenix how to convert a template path into quoted expressions.
See `Phoenix.Template.Engine` for more information on
the API required to be implemented by custom engines.

Once a template engine is defined, you can tell Phoenix
about it via the template engines option:

    config :phoenix, :template_engines,
      eex: Phoenix.Template.EExEngine,
      exs: Phoenix.Template.ExsEngine

## Format encoders

Besides template engines, Phoenix has the concept of format encoders.
Format encoders work per format and are responsible for encoding a
given format to a string. For example, when rendering JSON, your
templates may return a regular Elixir map. Then the JSON format
encoder is invoked to convert it to JSON.

A format encoder must export a function called `encode_to_iodata!/1`
which receives the rendering artifact and returns iodata.

New encoders can be added via the format encoder option:

    config :phoenix_template, :format_encoders,
      html: Phoenix.HTML.Engine

## __using__/1

Ensure `__mix_recompile__?/0` will be defined.

## embed_templates/2

A convenience macro for embeding templates as functions.

This macro is built on top of the more general `compile_all/3`
functionality.

## Options

  * `:root` - The root directory to embed files. Defaults to the current
    module's directory (`__DIR__`)
  * `:suffix` - The string value to append to embedded function names. By
    default, function names will be the name of the template file excluding
    the format and engine.

A wildcard pattern may be used to select all files within a directory tree.
For example, imagine a directory listing:

    ├── pages
    │   ├── about.html.heex
    │   └── sitemap.xml.eex

Then to embed the templates in your module:

    defmodule MyAppWeb.Renderer do
      import Phoenix.Template, only: [embed_templates: 1]
      embed_templates "pages/*"
    end

Now, your module will have a `about/1` and `sitemap/1` functions.
Note that functions across different formats were embedded. In case
you want to distinguish between them, you can give a more specific
pattern:

    defmodule MyAppWeb.Emails do
      import Phoenix.Template, only: [embed_templates: 2]

      embed_templates "pages/*.html", suffix: "_html"
      embed_templates "pages/*.xml", suffix: "_xml"
    end

Now the functions will be `about_html` and `sitemap_xml`.

## render_to_iodata/4

Renders the template and returns iodata.

## render_to_string/4

Renders the template to string.

## render/4

Renders template from module.

For a module called `MyApp.FooHTML` and template "index.html.heex",
it will:

  * First attempt to call `MyApp.FooHTML.index(assigns)`

  * Then fallback to `MyApp.FooHTML.render("index.html", assigns)`

  * Raise otherwise

It expects the HTML module, the template as a string, the format, and a
set of assigns.

Notice that this function returns the inner representation of a
template. If you want the encoded template as a result, use
`render_to_iodata/4` instead.

## Examples

    Phoenix.Template.render(YourApp.UserView, "index", "html", name: "John Doe")
    #=> {:safe, "Hello John Doe"}

## Assigns

Assigns are meant to be user data that will be available in templates.
However, there are keys under assigns that are specially handled by
Phoenix, they are:

  * `:layout` - tells Phoenix to wrap the rendered result in the
    given layout. See next section

## Layouts

Templates can be rendered within other templates using the `:layout`
option. `:layout` accepts a tuple of the form
`{LayoutModule, "template.extension"}`.

To template that goes inside the layout will be placed in the `@inner_content`
assign:

    <%= @inner_content %>

## format_encoder/1

Returns the format encoder for the given template.

## engines/0

Returns a keyword list with all template engines
extensions followed by their modules.

## find_all/3

Returns all template paths in a given template root.

## hash/3

Returns the hash of all template paths in the given root.

Used by Phoenix to check if a given root path requires recompilation.

## compile_all/4

Compiles a function for each template in the given `root`.

`converter` is an anonymous function that receives the template path
and returns the function name (as a string).

For example, to compile all `.eex` templates in a given directory,
you might do:

    Phoenix.Template.compile_all(
      &(&1 |> Path.basename() |> Path.rootname(".eex")),
      __DIR__,
      "*.eex"
    )

If the directory has templates named `foo.eex` and `bar.eex`,
they will be compiled into the functions `foo/1` and `bar/1`
that receive the template `assigns` as argument.

You may optionally pass a keyword list of engines. If a list
is given, we will lookup and compile only this subset of engines.
If none is passed (`nil`), the default list returned by `engines/0`
is used.