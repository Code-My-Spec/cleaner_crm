# NimbleOptions



## validate/2

Validates the given `options` with the given `schema`.

See the module documentation for what a `schema` is.

If the validation is successful, this function returns `{:ok, validated_options}`
where `validated_options` is a keyword list. If the validation fails, this
function returns `{:error, validation_error}` where `validation_error` is a
`NimbleOptions.ValidationError` struct explaining what's wrong with the options.
You can use `raise/1` with that struct or `Exception.message/1` to turn it into a string.

## validate!/2

Validates the given `options` with the given `schema` and raises if they're not valid.

This function behaves exactly like `validate/2`, but returns the options directly
if they're valid or raises a `NimbleOptions.ValidationError` exception otherwise.

## new!/1

Validates the given `schema` and returns a wrapped schema to be used with `validate/2`.

If the given schema is not valid, raises a `NimbleOptions.ValidationError`.

## option_typespec/1

Returns the quoted typespec for any option described by the given schema.

The returned quoted code represents the **type union** for all possible
keys in the schema, alongside their type. Nested keyword lists are
spec'ed as `t:keyword/0`.

## Usage

Because of how typespecs are treated by the Elixir compiler, you have
to use `unquote/1` on the return value of this function to use it
in a typespec:

    @type option() :: unquote(NimbleOptions.option_typespec(my_schema))

This function returns the type union for a single option: to give you
flexibility to combine it and use it in your own typespecs. For example,
if you only validate part of the options through NimbleOptions, you could
write a spec like this:

    @type my_option() ::
            {:my_opt1, integer()}
            | {:my_opt2, boolean()}
            | unquote(NimbleOptions.option_typespec(my_schema))

If you want to spec a whole schema, you could write something like this:

    @type options() :: [unquote(NimbleOptions.option_typespec(my_schema))]

## Example

    schema = [
      int: [type: :integer],
      number: [type: {:or, [:integer, :float]}]
    ]

    @type option() :: unquote(NimbleOptions.option_typespec(schema))

The code above would essentially compile to:

    @type option() :: {:int, integer()} | {:number, integer() | float()}