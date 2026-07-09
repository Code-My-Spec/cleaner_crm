# Cloak.Ecto.SHA256

An `Ecto.Type` which hashes the field value using the SHA256 algorithm.

## Why

If you store a hash of a field's value, you can then query on it as a proxy
for the encrypted field. This works because SHA256 is deterministic and
always results in the same value, while secure encryption does not. Be
warned, however, that hashing will expose which fields have the same value,
because they will contain the same hash.

## Security

For a more secure hashing method, see one of the following alternatives:

- `Cloak.Ecto.HMAC`
- `Cloak.Ecto.PBKDF2`

## Usage

Create the hash field with the type `:binary`. Add it to your schema
definition like this:

    schema "table" do
      field :field_name, MyApp.Encrypted.Binary
      field :field_name_hash, Cloak.Ecto.SHA256
    end

Ensure that the hash is updated whenever the target field changes with the
`put_change/3` function:

    def changeset(struct, attrs \\ %{}) do
      struct
      |> cast(attrs, [:field_name, :field_name_hash])
      |> put_change(:field_name_hash, get_field(changeset, :field_name))
    end

Query the Repo using the `:field_name_hash` in any place you would typically
query by `:field_name`.

    user = Repo.get_by(User, email_hash: "user@email.com")