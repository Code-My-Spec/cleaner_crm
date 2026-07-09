# Cloak.Ecto.Date

An `Ecto.Type` to encrypt `Date` fields.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.Date` module in your project:

    defmodule MyApp.Encrypted.Date do
      use Cloak.Ecto.Date, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.Date
    end