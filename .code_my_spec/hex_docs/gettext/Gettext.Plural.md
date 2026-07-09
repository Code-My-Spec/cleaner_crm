# Gettext.Plural

Behaviour and default implementation for finding plural forms in given
locales.

This module both defines the `Gettext.Plural` behaviour and provides a default
implementation for it.

## Plural Forms

> For a given language, there is a grammatical rule on how to change words
> depending on the number qualifying the word. Different languages can have
> different rules.
[[source]](https://udn.realityripple.com/docs/Mozilla/Localization/Localization_and_Plurals)

Such grammatical rules define a number of **plural forms**. For example,
English has two plural forms: one for when there is just one element (the
*singular*) and another one for when there are zero or more than one elements
(the *plural*). There are languages which only have one plural form and there
are languages which have more than two.

In GNU Gettext (and in Gettext for Elixir), plural forms are represented by
increasing 0-indexed integers. For example, in English `0` means singular and
`1` means plural.

The goal of this module is to determine, given a locale:

  * how many plural forms exist in that locale (`nplurals/1`);

  * to what plural form a given number of elements belongs to in that locale
    (`plural/2`).

## Default Implementation

`Gettext.Plural` provides a default implementation of a plural module. Most
common languages used on Earth should be covered by this default implementation. If
custom pluralization rules are needed (for example, to add additional
languages) a different plural module can be specified when creating a Gettext
backend. For example, pluralization rules for the Elvish language could be
added as follows:

    defmodule MyApp.Plural do
      @behaviour Gettext.Plural

      def nplurals("elv"), do: 3

      def plural("elv", 0), do: 0
      def plural("elv", 1), do: 1
      def plural("elv", _), do: 2

      # Fall back to Gettext.Plural
      defdelegate nplurals(locale), to: Gettext.Plural
      defdelegate plural(locale, n), to: Gettext.Plural
    end

The mathematical expressions used in this module to determine the plural form
of a given number of elements are taken from [this
page](http://localization-guide.readthedocs.org/en/latest/l10n/pluralforms.html#f2)
as well as from [Mozilla's guide on "Localization and
plurals"](https://udn.realityripple.com/docs/Mozilla/Localization/Localization_and_Plurals).

## Changing Implementations

Once you have defined your custom plural forms module, you can use it
in two ways. You can set it for all Gettext backends in your
configuration:

    # For example, in config/config.exs
    config :gettext, :plural_forms, MyApp.Plural

or you can set it for each specific backend when you call `use Gettext`:

    defmodule MyApp.Gettext do
      use Gettext.Backend,
        otp_app: :my_app,
        plural_forms: MyApp.Plural
    end

> #### Compile-time Configuration {: .warning}
>
> Set `:plural_forms` in your `config/config.exs` and
> not in `config/runtime.exs`, as Gettext reads this option when
> compiling your backends.

Task such as `mix gettext.merge` use the plural
backend configured under the `:gettext` application, so in general
the global configuration approach is preferred.

Some tasks also allow the number of plural forms to be given
explicitly, for example:

    mix gettext.merge priv/gettext --locale=gsw_CH --plural-forms=2

## Unknown Locales

Trying to call `Gettext.Plural` functions with unknown locales will result in
a `Gettext.Plural.UnknownLocaleError` exception.

## Language and Territory

Often, a locale is composed as a language and territory pair, such as
`en_US`. The default implementation for `Gettext.Plural` handles `xx_YY` by
forwarding it to `xx` (except for *just Brazilian Portuguese*, `pt_BR`, which
is not forwarded to `pt` as pluralization rules differ slightly). We treat the
underscore as a separator according to
[ISO 15897](https://en.wikipedia.org/wiki/ISO/IEC_15897). Sometimes, a dash `-` is
used as a separator (for example [BCP47](https://en.wikipedia.org/wiki/IETF_language_tag)
locales use this as in `en-US`): this is *not forwarded* to `en` in the default
`Gettext.Plural` (and it will raise an `Gettext.Plural.UnknownLocaleError` exception
if there are no messages for `en-US`). We recommend defining a custom plural forms
module that replaces `-` with `_` if needed.

## Examples

An example of the plural form of a given number of elements in the Polish
language:

    iex> Gettext.Plural.plural("pl", 1)
    0
    iex> Gettext.Plural.plural("pl", 2)
    1
    iex> Gettext.Plural.plural("pl", 5)
    2
    iex> Gettext.Plural.plural("pl", 112)
    2

As expected, `nplurals/1` returns the possible number of plural forms:

    iex> Gettext.Plural.nplurals("pl")
    3

## init/1

Should return the value of the `Plural-Forms` header for the given `locale`,
if present.

If the value of the `Plural-Forms` header is unavailable for any reason, this
function should return `nil`.

This callback is optional. If it's not defined, the fallback returns:

    "nplurals={nplurals};"

## nplurals/1

Default implementation of the `c:nplurals/1` callback.

## plural/2

Default implementation of the `c:plural/2` callback.