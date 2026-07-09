# Cloak.Ecto.Decimal

An `Ecto.Type` to encrypt a decimal field, relying on the `Decimal`
library, which is a dependency of Ecto.

Decimals are more precise than floats.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.Decimal` module in your project:

    defmodule MyApp.Encrypted.Decimal do
      use Cloak.Ecto.Decimal, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.Decimal
    end