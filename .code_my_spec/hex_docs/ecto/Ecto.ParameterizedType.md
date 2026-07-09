# Ecto.ParameterizedType

Parameterized types are Ecto types that can be customized per field.

Parameterized types allow a set of options to be specified in the schema
which are initialized on compilation and passed to the callback functions
as the last argument.

For example, `field :foo, :string` behaves the same for every field.
On the other hand, `field :foo, Ecto.Enum, values: [:foo, :bar, :baz]`
will likely have a different set of values per field.

Note that options are specified as a keyword, but it is idiomatic to
convert them to maps inside `c:init/1` for easier pattern matching in
other callbacks.

Parameterized types are a superset of regular types. In other words,
with parameterized types you can do everything a regular type does,
and more. For example, parameterized types can handle `nil` values
in both `load` and `dump` callbacks, they can customize `cast` behavior
per query and per changeset, and also control how values are embedded.

However, parameterized types are also more complex. Therefore, if
everything you need to achieve can be done with basic types, they
should be preferred to parameterized ones.

## Examples

To create a parameterized type, create a module as shown below:

    defmodule MyApp.MyType do
      use Ecto.ParameterizedType

      def type(_params), do: :string

      def init(opts) do
        validate_opts(opts)
        Enum.into(opts, %{})
      end

      def cast(data, params) do
        ...
        {:ok, cast_data}
      end

      def load(data, _loader, params) do
        ...
        {:ok, loaded_data}
      end

      def dump(data, dumper, params) do
        ...
        {:ok, dumped_data}
      end

      def equal?(a, b, _params) do
        a == b
      end
    end

To use this type in a schema field, specify the type and parameters like this:

    schema "foo" do
      field :bar, MyApp.MyType, opt1: :baz, opt2: :boo
    end

To use this type in a schema field with a composite type, specify the type in a tuple
and opts afterwards.

    schema "foo" do
      field :bars, {:array, MyApp.MyType}, opt1: :baz, opt2: :boo
    end

To use this type in places where you need it to be initialized (for example,
schemaless changesets), you can use `init/2`.

> #### `use Ecto.ParameterizedType` {: .info}
>
> When you `use Ecto.ParameterizedType`, it will set
> `@behaviour Ecto.ParameterizedType` and define default, overridable
> implementations for `c:embed_as/2` and `c:equal?/3`.

## init/2

Inits a parameterized type given by `type` with `opts`.

Useful when manually initializing a type for schemaless changesets.