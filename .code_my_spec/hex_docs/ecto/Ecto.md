# Ecto



## primary_key/1

Returns the schema primary keys as a keyword list.

## primary_key!/1

Returns the schema primary keys as a keyword list.

Raises `Ecto.NoPrimaryKeyFieldError` if the schema has no
primary key field.

## build_assoc/3

Builds a struct from the given `assoc` in `struct`.

## Examples

If the relationship is a `has_one` or `has_many` and
the primary key is set in the parent struct, the key will
automatically be set in the built association:

    iex> post = Repo.get(Post, 13)
    %Post{id: 13}
    iex> build_assoc(post, :comments)
    %Comment{id: nil, post_id: 13}

Note though it doesn't happen with `belongs_to` cases, as the
key is often the primary key and such is usually generated
dynamically:

    iex> comment = Repo.get(Comment, 13)
    %Comment{id: 13, post_id: 25}
    iex> build_assoc(comment, :post)
    %Post{id: nil}

You can also pass the attributes, which can be a map or
a keyword list, to set the struct's fields except the
association key.

    iex> build_assoc(post, :comments, text: "cool")
    %Comment{id: nil, post_id: 13, text: "cool"}

    iex> build_assoc(post, :comments, %{text: "cool"})
    %Comment{id: nil, post_id: 13, text: "cool"}

    iex> build_assoc(post, :comments, post_id: 1)
    %Comment{id: nil, post_id: 13}

The given attributes are expected to be structured data.
If you want to build an association with external data,
such as a request parameters, you can use `Ecto.Changeset.cast/3`
after `build_assoc/3`:

    parent
    |> Ecto.build_assoc(:child)
    |> Ecto.Changeset.cast(params, [:field1, :field2])

## assoc/3

Builds a query for the association in the given struct or structs.

## Examples

In the example below, we get all comments associated to the given
post:

    post = Repo.get Post, 1
    Repo.all Ecto.assoc(post, :comments)

`assoc/3` can also receive a list of posts, as long as the posts are
not empty:

    posts = Repo.all from p in Post, where: is_nil(p.published_at)
    Repo.all Ecto.assoc(posts, :comments)

This function can also be used to dynamically load through associations
by giving it a list. For example, to get all authors for all comments for
the given posts, do:

    posts = Repo.all from p in Post, where: is_nil(p.published_at)
    Repo.all Ecto.assoc(posts, [:comments, :author])

## Options

  * `:prefix` - the prefix to fetch assocs from. By default, queries
    will use the same prefix as the first struct in the given collection.
    This option allows the prefix to be changed.

## assoc_loaded?/1

Checks if an association is loaded.

## Examples

    iex> post = Repo.get(Post, 1)
    iex> Ecto.assoc_loaded?(post.comments)
    false
    iex> post = post |> Repo.preload(:comments)
    iex> Ecto.assoc_loaded?(post.comments)
    true

## reset_fields/2

Resets fields in a struct to their default values.

## Examples

    iex> post = post |> Repo.preload(:author)
    %Post{title: "hello world", author: %Author{}}
    iex> Ecto.reset_fields(post, [:title, :author])
    %Post{
      title: "default title",
      author: #Ecto.Association.NotLoaded<association :author is not loaded>
    }

## get_meta/2

Gets the metadata from the given struct.

For example, to check whether it has been persisted:

    iex> Ecto.get_meta(changeset.data, :state)
    :built

See `Ecto.Schema.Metadata`.

## put_meta/2

Returns a new struct with updated metadata.

It is possible to set:

  * `:source` - changes the struct query source
  * `:prefix` - changes the struct query prefix
  * `:context` - changes the struct meta context
  * `:state` - changes the struct state

See `Ecto.Schema.Metadata`.

## embedded_load/3

Loads previously dumped `data` in the given `format` into a schema.

The first argument can be an embedded schema module, or a map (of types) and
determines the return value: a struct or a map, respectively.

The second argument `data` specifies fields and values that are to be loaded.
It can be a map, a keyword list, or a `{fields, values}` tuple. Fields can be
atoms or strings.

The third argument `format` is the format the data has been dumped as. For
example, databases may dump embedded to `:json`, this function allows such
dumped data to be put back into the schemas. If custom types are used,
Ecto will invoke the `c:Ecto.Type.embed_as/1` callback to decide if the data
should be loaded using `cast` or `load`.

Fields that are not present in the schema (or `types` map) are ignored.
If any of the values has invalid type, an error is raised.

Note that if you want to load data into a non-embedded schema that was
directly persisted into a given repository, then use `c:Ecto.Repo.load/2`.

## Examples

    iex> result = Ecto.Adapters.SQL.query!(MyRepo, "SELECT users.settings FROM users", [])
    iex> Enum.map(result.rows, fn [settings] -> Ecto.embedded_load(Setting, Jason.decode!(settings), :json) end)
    [%Setting{...}, ...]

## embedded_dump/2

Dumps the given struct defined by an embedded schema.

This converts the given embedded schema to a map to be serialized
with the given format. For example:

    iex> Ecto.embedded_dump(%Post{}, :json)
    %{title: "hello"}