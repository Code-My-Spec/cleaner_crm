# Gettext.Macros

Macros used by Gettext to provide the gettext family of functions.

*Available since v0.26.0.*

Macros enable users to use gettext and get **automatic extraction** of translations.
See `Gettext` for more information.

The macros in this module *that don't end with `_with_backend`* are imported
every time you call:

    use Gettext, backend: MyApp.Gettext

### Explicit backend

If you need to use the macros here with an explicit backend and you want extraction
to work, you can use the `_with_backend` versions of the macros in this module explicitly
instead.

    defmodule MyApp.Gettext do
      use Gettext, otp_app: :my_app
    end

    defmodule MyApp.Controller do
      require Gettext.Macros

      def index(conn, _params) do
        Gettext.Macros.gettext_with_backend(MyApp.Gettext, "Hello, world!")
      end
    end

## dpgettext_noop/3

Marks the given message for extraction and returns it unchanged.

This macro can be used to mark a message for extraction when `mix
gettext.extract` is run. The return value is the given string, so that this
macro can be used seamlessly in place of the string to extract.

## Examples

    dpgettext_noop("errors", "Home page", "Error found!")
    #=> "Error found!"

## dgettext_noop/2

Marks the given message for extraction and returns it unchanged.

This macro can be used to mark a message for extraction when `mix
gettext.extract` is run. The return value is the given string, so that this
macro can be used seamlessly in place of the string to extract.

## Examples

    dgettext_noop("errors", "Error found!")
    #=> "Error found!"

## gettext_noop/1

Marks the given message for extraction and returns it unchanged.

This macro can be used to mark a message for extraction when `mix
gettext.extract` is run. The return value is the given string, so that this
macro can be used seamlessly in place of the string to extract.

## Examples

    gettext_noop("Error found!")
    #=> "Error found!"

## pgettext_noop/2

Marks the given message for extraction and returns it unchanged.

This macro can be used to mark a message for extraction when `mix
gettext.extract` is run. The return value is the given string, so that this
macro can be used seamlessly in place of the string to extract.

## Examples

    pgettext_noop("Error found!", "Home page")
    #=> "Error found!"

## dpngettext_noop/4

Marks the given message for extraction and returns it unchanged.

This macro can be used to mark a message for extraction when `mix
gettext.extract` is run. The return value is the given string, so that this
macro can be used seamlessly in place of the string to extract.

## Examples

    dpngettext_noop("errors", "Home page", "Error found!", "Errors found!")
    #=> "Error found!"

## dngettext_noop/3

Marks the given message for extraction and returns
`{msgid, msgid_plural}`.

This macro can be used to mark a message for extraction when `mix
gettext.extract` is run. The return value of this macro is `{msgid,
msgid_plural}`.

## Examples

    my_fun = fn {msgid, msgid_plural} ->
      # do something with msgid and msgid_plural
    end

    my_fun.(dngettext_noop("errors", "One error", "%{count} errors"))

## pngettext_noop/3

Marks the given message for extraction and returns it unchanged.

This macro can be used to mark a message for extraction when `mix
gettext.extract` is run. The return value is the given string, so that this
macro can be used seamlessly in place of the string to extract.

## Examples

    pngettext_noop("Home page", "Error found!", "Errors found!")
    #=> "Error found!"

## ngettext_noop/2

Same as `dngettext_noop("default", msgid, mgsid_plural)`, but will use a
per-backend configured default domain if provided.

## dpgettext/4

Translates the given `msgid` with a given context (`msgctxt`) in the given `domain`.

`bindings` is a map of bindings to support interpolation.

See also `Gettext.dpgettext/5`.

## dgettext/3

Translates the given `msgid` in the given `domain`.

`bindings` is a map of bindings to support interpolation.

See also `Gettext.dgettext/4`.

## pgettext/3

Translates the given `msgid` with the given context (`msgctxt`).

`bindings` is a map of bindings to support interpolation.

See also `Gettext.pgettext/4`.

## gettext/2

Same as `dgettext("default", msgid, %{})`, but will use a per-backend
configured default domain if provided.

See also `Gettext.gettext/3`.

## dpngettext/6

Translates the given plural message (`msgid` + `msgid_plural`) with the given context (`msgctxt`)
in the given `domain`.

`n` is an integer used to determine how to pluralize the
message. `bindings` is a map of bindings to support interpolation.

See also `Gettext.dpngettext/7`.

## dngettext/5

Translates the given plural message (`msgid` + `msgid_plural`) in the
given `domain`.

`n` is an integer used to determine how to pluralize the
message. `bindings` is a map of bindings to support interpolation.

See also `Gettext.dngettext/6`.

## ngettext/4

Same as `dngettext("default", msgid, msgid_plural, n, bindings)`, but will
use a per-backend configured default domain if provided.

See also `Gettext.ngettext/5`.

## pngettext/5

Translates the given plural message (`msgid` + `msgid_plural`) with the given context (`msgctxt`).

`n` is an integer used to determine how to pluralize the
message. `bindings` is a map of bindings to support interpolation.

See also `Gettext.pngettext/6`.

## gettext_comment/1

Stores an "extracted comment" for the next message.

This macro can be used to add comments (Gettext refers to such
comments as *extracted comments*) to the next message that will
be extracted. Extracted comments will be prefixed with `#.` in POT
files.

Calling this function multiple times will accumulate the comments;
when another Gettext macro (such as `gettext/2`) is called,
the comments will be extracted and attached to that message, and
they will be flushed so as to start again.

This macro always returns `:ok`.

## Examples

    gettext_comment("The next message is awesome")
    gettext_comment("Another comment for the next message")
    gettext("The awesome message")

## dpgettext_noop_with_backend/4

Same as `dpgettext_noop/3`, but takes an explicit backend.

## dgettext_noop_with_backend/3

Same as `dgettext_noop/2`, but takes an explicit backend.

## pgettext_noop_with_backend/3

Same as `pgettext_noop/2`, but takes an explicit backend.

## gettext_noop_with_backend/2

Same as `gettext_noop/1`, but takes an explicit backend.

## dpngettext_noop_with_backend/5

Same as `dpngettext_noop/4`, but takes an explicit backend.

## dngettext_noop_with_backend/4

Same as `dngettext_noop/3`, but takes an explicit backend.

## pngettext_noop_with_backend/4

Same as `pngettext_noop/3`, but takes an explicit backend.

## ngettext_noop_with_backend/3

Same as `ngettext_noop/2`, but takes an explicit backend.

## dpgettext_with_backend/5

Same as `dpgettext/4`, but takes an explicit backend.

## dgettext_with_backend/4

Same as `dgettext/3`, but takes an explicit backend.

## pgettext_with_backend/4

Same as `pgettext/3`, but takes an explicit backend.

## gettext_with_backend/3

Same as `gettext/2`, but takes an explicit backend.

## dpngettext_with_backend/7

Same as `dpngettext/6`, but takes an explicit backend.

## dngettext_with_backend/6

Same as `dngettext/5`, but takes an explicit backend.

## pngettext_with_backend/6

Same as `pngettext/5`, but takes an explicit backend.

## ngettext_with_backend/5

Same as `ngettext/4`, but takes an explicit backend.