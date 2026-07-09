# Cloak.Ecto.Integer

An `Ecto.Type` to encrypt integer fields.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.Integer` module in your project:

    defmodule MyApp.Encrypted.Integer do
      use Cloak.Ecto.Integer, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.Integer
    end