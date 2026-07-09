# Cloak.Ecto.Time

An `Ecto.Type` to encrypt `Time` fields.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.Time` module in your project:

    defmodule MyApp.Encrypted.Time do
      use Cloak.Ecto.Time, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.Time
    end