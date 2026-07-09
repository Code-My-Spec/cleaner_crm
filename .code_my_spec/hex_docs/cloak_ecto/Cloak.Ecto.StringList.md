# Cloak.Ecto.StringList

An `Ecto.Type` to encrypt a list of strings.

## Configuration

You can customize the json library used for for converting lists.

    config :my_app, MyApp.Vault,
      json_library: Jason

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.StringList` module in your project:

    defmodule MyApp.Encrypted.StringList do
      use Cloak.Ecto.StringList, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.StringList
    end

On encryption, the list will first be converted to JSON using the configured
`:json_library`, and then encrypted. On decryption, the `:json_library` will
be used to convert it back to a list of strings.