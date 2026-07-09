# Phoenix.Naming

Conveniences for inflecting and working with names in Phoenix.

## resource_name/2

Extracts the resource name from an alias.

## Examples

    iex> Phoenix.Naming.resource_name(MyApp.User)
    "user"

    iex> Phoenix.Naming.resource_name(MyApp.UserView, "View")
    "user"

## unsuffix/2

Removes the given suffix from the name if it exists.

## Examples

    iex> Phoenix.Naming.unsuffix("MyApp.User", "View")
    "MyApp.User"

    iex> Phoenix.Naming.unsuffix("MyApp.UserView", "View")
    "MyApp.User"

## underscore/1

Converts a string to underscore case.

## Examples

    iex> Phoenix.Naming.underscore("MyApp")
    "my_app"

In general, `underscore` can be thought of as the reverse of
`camelize`, however, in some cases formatting may be lost:

    Phoenix.Naming.underscore "SAPExample"  #=> "sap_example"
    Phoenix.Naming.camelize   "sap_example" #=> "SapExample"

## camelize/1

Converts a string to camel case.

Takes an optional `:lower` flag to return lowerCamelCase.

## Examples

    iex> Phoenix.Naming.camelize("my_app")
    "MyApp"

    iex> Phoenix.Naming.camelize("my_app", :lower)
    "myApp"

In general, `camelize` can be thought of as the reverse of
`underscore`, however, in some cases formatting may be lost:

    Phoenix.Naming.underscore "SAPExample"  #=> "sap_example"
    Phoenix.Naming.camelize   "sap_example" #=> "SapExample"

## humanize/1

Converts an attribute/form field into its humanize version.

## Examples

    iex> Phoenix.Naming.humanize(:username)
    "Username"
    iex> Phoenix.Naming.humanize(:created_at)
    "Created at"
    iex> Phoenix.Naming.humanize("user_id")
    "User"