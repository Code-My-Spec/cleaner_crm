# Bunt

`Bunt` enables 256 color ANSI coloring in the terminal and gives you the ability to alias colors to more semantic and application-specfic names.



### Augment `IO.ANSI`

`IO.ANSI` provides an interface to write text to the terminal in eight different colors like this:

    ["Hello, ", :red, :bright, "world!"]
    |> IO.ANSI.format
    |> IO.puts

This will put the word "world!" in bright red.

To cause as little friction as possible, the interface of `Bunt.ANSI` is 100% adapted from `IO.ANSI`.

We can use `Bunt` in the same way:

    ["Hello, ", :color202, :bright, "world!"]
    |> Bunt.ANSI.format
    |> IO.puts

which puts a bright orange-red `"world!"` on the screen.

`Bunt` also provides a shortcut so we can skip the `format` call.

    ["Hello, ", :color202, :bright, "world!"]
    |> Bunt.puts

and since nobody can remember that `:color202` is basically `:orangered`, you can use `:orangered` directly.



### Named colors

The following colors were given names, so you can use them in style:

    [:gold, "Look, it's really gold text!"]
    |> Bunt.puts

Replace `:gold` with any of these values:

    darkblue      mediumblue    darkgreen     darkslategray darkcyan
    deepskyblue   springgreen   aqua          dimgray       steelblue
    darkred       darkmagenta   olive         chartreuse    aquamarine
    greenyellow   chocolate     goldenrod     lightgray     beige
    lightcyan     fuchsia       orangered     hotpink       darkorange
    coral         orange        gold          khaki         moccasin
    mistyrose     lightyellow

You can see all supported colors by cloning the repo and running:

    $ mix run script/colors.exs

### User-defined color aliases

But since all these colors are hard to remember, you can alias them in your config.exs:

    # I tend to start the names of my color aliases with an underscore
    # but this is, naturally, not a must.

    config :bunt, color_aliases: [_cupcake: :color205]

Then you can use these keys instead of the standard colors in your code:

    [:_cupcake, "Hello World!"]
    |> Bunt.puts

Use this to give your colors semantics. They get easier to change later that way. (A colleague of mine shouted "It's CSS for console applications!" when he saw this and although that is ... well, not true, I really like the sentiment! :+1:)

## puts/1

Formats and writes `value` to `stdout`, similar to `write/1`, but adds a newline at the end.

## Examples

    Bunt.puts([:bright, :green, "Success!"])

## warn/1

Formats and writes `value` to `stderr`.

## Examples

    Bunt.puts([:bright, :red, "Warning!"])

## write/1

Formats and writes `value` to `stdout`.

## Examples

    Bunt.write([:bright, :cyan, "Info!"])

## format/1

Formats `value` by converting named ANSI sequences into actual ANSI codes.

## Examples

    Bunt.format([:bright, :cyan, "Info!"])

## version/0

Returns the version of Bunt.