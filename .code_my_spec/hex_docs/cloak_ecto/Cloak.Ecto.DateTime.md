# Cloak.Ecto.DateTime

An `Ecto.Type` to encrypt `DateTime` fields.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.DateTime` module in your project:

    defmodule MyApp.Encrypted.DateTime do
      use Cloak.Ecto.DateTime, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.DateTime
    end