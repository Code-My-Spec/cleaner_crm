# Gettext



## get_locale/0

Gets the global Gettext locale for the current process.

This function returns the value of the global Gettext locale for the current
process. This global locale is shared between all Gettext backends; if you
want backend-specific locales, see `get_locale/1` and `put_locale/2`. If the
global Gettext locale is not set, this function returns the default global
locale (configurable in the configuration for the `:gettext` application, see
the module documentation for more information).

## Examples

    Gettext.get_locale()
    #=> "en"

## put_locale/1

Sets the **global** Gettext locale for the current process.

The locale is stored in the process dictionary. `locale` must be a string; if
it's not, an `ArgumentError` exception is raised.

The return value is the previous value of the current
process's locale.

> #### Unknown Locales {: .warning}
>
> Since this function sets the *global* locale, it cannot check whether that
> local is supported against a particular backend. For that, use `put_locale/2`
> or `put_locale!/2`.

## Examples

    Gettext.put_locale("pt_BR")
    #=> nil
    Gettext.get_locale()
    #=> "pt_BR"

## get_locale/1

Gets the locale for the current process and the given backend.

This function returns the value of the locale for the current process and the
given `backend`. If there is no locale for the current process and the given
backend, then either the global Gettext locale (if set), or the default locale
for the given backend, or the global default locale is returned. See the
"Locale" section in the module documentation for more information.

## Examples

    Gettext.get_locale(MyApp.Gettext)
    #=> "en"

## put_locale/2

Sets the locale for the current process and the given `backend`.

The locale is stored in the process dictionary. `locale` must be a string; if
it's not, an `ArgumentError` exception is raised.

The return value is the previous value of the current
process's locale.

## Examples

    Gettext.put_locale(MyApp.Gettext, "pt_BR")
    #=> nil
    Gettext.get_locale(MyApp.Gettext)
    #=> "pt_BR"

The current process's locale will change even if the passed `locale` is not
supported. If you think this can cause an issue consider using `known_locales/1`
to handle unsupported locales:

    # Handle unsupported locales based on your requirements
    defp handle_locale(locale, true, backend), do: {:ok, Process.put(backend, locale)}
    defp handle_locale(_locale, false, backend), do: {:error, :unsupported_locale}

    # In your main function
    is_in_allowed_locale = locale in known_locales(backend)
    handle_locale(locale, is_in_allowed_locale, backend)

Alternatively, use `put_locale!/2` which raises if the locale is not supported.

## put_locale!/2

Like `put_locale/2`, but it raises an error if the passed locale doesn't exist in the known locales.

  ## Examples

    Gettext.put_locale(MyApp.Gettext, "pt_BR")
    #=> nil
    Gettext.get_locale(MyApp.Gettext)
    #=> "pt_BR"

## dpgettext/5

Returns the message of the given string with a given context in the given domain.

The string is translated by the `backend` module.

The translated string is interpolated based on the `bindings` argument. For
more information on how interpolation works, refer to the documentation of the
`Gettext` module.

If the message for the given `msgid` is not found, the `msgid`
(interpolated if necessary) is returned.

## Examples

    defmodule MyApp.Gettext do
      use Gettext.Backend, otp_app: :my_app
    end

    Gettext.put_locale(MyApp.Gettext, "it")

    Gettext.dpgettext(MyApp.Gettext, "errors", "user error", "Invalid")
    #=> "Non valido"

    Gettext.dgettext(MyApp.Gettext, "errors", "signup form", "%{name} is not a valid name", name: "Meg")
    #=> "Meg non è un nome valido"

## dgettext/4

Returns the message of the given string in the given domain.

The string is translated by the `backend` module.

The translated string is interpolated based on the `bindings` argument. For
more information on how interpolation works, refer to the documentation of the
`Gettext` module.

If the message for the given `msgid` is not found, the `msgid`
(interpolated if necessary) is returned.

## Examples

    defmodule MyApp.Gettext do
      use Gettext.Backend, otp_app: :my_app
    end

    Gettext.put_locale(MyApp.Gettext, "it")

    Gettext.dgettext(MyApp.Gettext, "errors", "Invalid")
    #=> "Non valido"

    Gettext.dgettext(MyApp.Gettext, "errors", "%{name} is not a valid name", name: "Meg")
    #=> "Meg non è un nome valido"

    Gettext.dgettext(MyApp.Gettext, "alerts", "nonexisting")
    #=> "nonexisting"

## pgettext/4

Returns the message of the given string with the given context

The string is translated by the `backend` module.

The translated string is interpolated based on the `bindings` argument. For
more information on how interpolation works, refer to the documentation of the
`Gettext` module.

If the message for the given `msgid` is not found, the `msgid`
(interpolated if necessary) is returned.

## Examples

    defmodule MyApp.Gettext do
      use Gettext.Backend, otp_app: :my_app
    end

    Gettext.put_locale(MyApp.Gettext, "it")

    Gettext.pgettext(MyApp.Gettext, "user-interface", "Invalid")
    #=> "Non valido"

    Gettext.pgettext(MyApp.Gettext, "user-interface", "%{name} is not a valid name", name: "Meg")
    #=> "Meg non è un nome valido"

    Gettext.pgettext(MyApp.Gettext, "alerts-users", "nonexisting")
    #=> "nonexisting"

## gettext/3

Returns the message of the given string in the `"default"` domain.

Works exactly like:

    Gettext.dgettext(backend, "default", msgid, bindings)

## dpngettext/7

Returns the pluralized message of the given string with a given context in the given domain.

The string is translated and pluralized by the `backend` module.

The translated string is interpolated based on the `bindings` argument. For
more information on how interpolation works, refer to the documentation of the
`Gettext` module.

If the message for the given `msgid` and `msgid_plural` is not found, the
`msgid` or `msgid_plural` (based on `n` being singular or plural) is returned
(interpolated if necessary).

## Examples

    defmodule MyApp.Gettext do
      use Gettext.Backend, otp_app: :my_app
    end

    Gettext.dpngettext(MyApp.Gettext, "errors", "user error", "Error", "%{count} errors", 3)
    #=> "3 errori"
    Gettext.dpngettext(MyApp.Gettext, "errors", "user error", "Error", "%{count} errors", 1)
    #=> "Errore"

## dngettext/6

Returns the pluralized message of the given string in the given domain.

The string is translated and pluralized by the `backend` module.

The translated string is interpolated based on the `bindings` argument. For
more information on how interpolation works, refer to the documentation of the
`Gettext` module.

If the message for the given `msgid` and `msgid_plural` is not found, the
`msgid` or `msgid_plural` (based on `n` being singular or plural) is returned
(interpolated if necessary).

## Examples

    defmodule MyApp.Gettext do
      use Gettext.Backend, otp_app: :my_app
    end

    Gettext.dngettext(MyApp.Gettext, "errors", "Error", "%{count} errors", 3)
    #=> "3 errori"
    Gettext.dngettext(MyApp.Gettext, "errors", "Error", "%{count} errors", 1)
    #=> "Errore"

## pngettext/6

Returns the pluralized message of the given string with a given context
in the `"default"` domain.

Works exactly like:

    Gettext.dpngettext(backend, "default", context, msgid, msgid_plural, n, bindings)

## ngettext/5

Returns the pluralized message of the given string in the `"default"`
domain.

Works exactly like:

    Gettext.dngettext(backend, "default", msgid, msgid_plural, n, bindings)

## with_locale/2

Runs `fun` with the global Gettext locale set to `locale`.

This function just sets the global Gettext locale to `locale` before running
`fun` and sets it back to its previous value afterwards. Note that
`put_locale/2` is used to set the locale, which is thus set only for the
current process (keep this in mind if you plan on spawning processes inside
`fun`).

The value returned by this function is the return value of `fun`.

## Examples

    Gettext.put_locale("fr")

    gettext("Hello world")
    #=> "Bonjour monde"

    Gettext.with_locale("it", fn ->
      gettext("Hello world")
    end)
    #=> "Ciao mondo"

    gettext("Hello world")
    #=> "Bonjour monde"

## with_locale/3

Runs `fun` with the Gettext locale set to `locale` for the given `backend`.

This function just sets the Gettext locale for `backend` to `locale` before
running `fun` and sets it back to its previous value afterwards. Note that
`put_locale/2` is used to set the locale, which is thus set only for the
current process (keep this in mind if you plan on spawning processes inside
`fun`).

The value returned by this function is the return value of `fun`.

## Examples

    Gettext.put_locale(MyApp.Gettext, "fr")

    gettext("Hello world")
    #=> "Bonjour monde"

    Gettext.with_locale(MyApp.Gettext, "it", fn ->
      gettext("Hello world")
    end)
    #=> "Ciao mondo"

    gettext("Hello world")
    #=> "Bonjour monde"

## known_locales/1

Returns all the locales for which PO files exist for the given `backend`.

If the messages directory for the given backend doesn't exist, then an
empty list is returned.

## Examples

With the following backend:

    defmodule MyApp.Gettext do
      use Gettext.Backend, otp_app: :my_app
    end

and the following messages directory:

    my_app/priv/gettext
    ├─ en
    ├─ it
    └─ pt_BR

then:

    Gettext.known_locales(MyApp.Gettext)
    #=> ["en", "it", "pt_BR"]