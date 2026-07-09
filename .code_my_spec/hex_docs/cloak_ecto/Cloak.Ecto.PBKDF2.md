# Cloak.Ecto.PBKDF2

A custom `Ecto.Type` for deriving a key for fields using
[PBKDF2](https://en.wikipedia.org/wiki/PBKDF2).

PBKDF2 is **more secure** than `Cloak.Ecto.HMAC` and
`Cloak.Fields.SHA256` because it uses [key
stretching](https://en.wikipedia.org/wiki/Key_stretching) to increase the
amount of time to compute hashes. This slows down brute-force attacks.

## Why

If you store a hash of a field's value, you can then query on it as a
proxy for an encrypted field. This works because PBKDF2 is deterministic
and always results in the same value, while secure encryption does not.
Be warned, however, that hashing will expose which fields have the same
value, because they will contain the same hash.

## Dependency

To use this field type, you must install the `:pbkdf2` library in your
`mix.exs` file.

    {:pbkdf2, "~> 2.0"}

If you are using Erlang >= 24, you will need to use a forked version,
because `pbkdf2` version `2.0.0` uses `:crypto.hmac` functions that were
removed in Erlang 24.

    {:pbkdf2, "~> 2.0", github: "miniclip/erlang-pbkdf2"}

## Configuration

Create a `PBKDF2` field in your project:

    defmodule MyApp.Hashed.PBKDF2 do
      use Cloak.Ecto.PBKDF2, otp_app: :my_app
    end

Then, configure it with a `:secret`, an `:algorithm`, the maximum `:size`
of the stored key (in bytes), and a number of `:iterations`, either using
mix configuration:

    config :my_app, MyApp.Hashed.PBKDF2,
      algorithm: :sha256,
      iterations: 600_000,
      secret: "secret",
      size: 64

Or using the `init/1` callback to fetch configuration at runtime:

    defmodule MyApp.Hashed.PBKDF2 do
      use Cloak.Ecto.PBKDF2, otp_app: :my_app

      @impl Cloak.Ecto.PBKDF2
      def init(config) do
        config = Keyword.merge(config, [
          algorithm: :sha256,
          iterations: 600_000,
          secret: System.get_env("PBKDF2_SECRET")
        ])

        {:ok, config}
      end
    end

## Usage

Create the hash field with the type `:binary`. Add it to your schema
definition like this:

    schema "table" do
      field :field_name, MyApp.Encrypted.Binary
      field :field_name_hash, MyApp.Hashed.PBKDF2
    end

Ensure that the hash is updated whenever the target field changes with the
`put_change/3` function:

    def changeset(struct, attrs \\ %{}) do
      struct
      |> cast(attrs, [:field_name, :field_name_hash])
      |> put_hashed_fields()
    end

    defp put_hashed_fields(changeset) do
      changeset
      |> put_change(:field_name_hash, get_field(changeset, :field_name))
    end

Query the Repo using the `:field_name_hash` in any place you would typically
query by `:field_name`.

    user = Repo.get_by(User, email_hash: "user@email.com")

## __using__/1

Configures the `PBKDF2` field using runtime information.

## Example

    @impl Cloak.Ecto.PBKDF2
    def init(config) do
      config = Keyword.merge(config, [
        algorithm: :sha256,
        secret: System.get_env("PBKDF2_SECRET")
      ])

      {:ok, config}
    end