# Gettext.Backend

Defines a Gettext backend.

## Usage

A Gettext **backend** must `use` this module.

    defmodule MyApp.Gettext do
      use Gettext.Backend, otp_app: :my_app
    end

Using this module generates all the callbacks required by the `Gettext.Backend`
behaviour into the module that uses it. For more options and information,
see `Gettext`.

> #### `use Gettext.Backend` Is a Recent Feature {: .info}
>
> Before version v0.26.0, you could only `use Gettext` to generate a backend.
>
> Version v0.26.0 changes the way backends work so that now a Gettext backend
> must `use Gettext.Backend`, while to use the functions in the backend you
> will do `use Gettext, backend: MyApp.Gettext`.