# Cloak.Ecto.NaiveDateTime

An `Ecto.Type` to encrypt `NaiveDateTime` fields.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.NaiveDateTime` module in your project:

    defmodule MyApp.Encrypted.NaiveDateTime do
      use Cloak.Ecto.NaiveDateTime, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.NaiveDateTime
    end