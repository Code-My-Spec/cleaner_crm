# Cloak.Ecto.Float

An `Ecto.Type` to encrypt a float field. Consider using `Cloak.Ecto.Decimal`
instead if precision is important.

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.Float` module in your project:

    defmodule MyApp.Encrypted.Float do
      use Cloak.Ecto.Float, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.Float
    end