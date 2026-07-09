# Cloak.Ecto.Binary

An `Ecto.Type` to encrypt a binary field.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.Binary` module in your project:

    defmodule MyApp.Encrypted.Binary do
      use Cloak.Ecto.Binary, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.Binary
    end