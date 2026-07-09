# Cloak.Ecto.IntegerList

An `Ecto.Type` to encrypt a list of integers.

## Configuration

You can customize the json library used for for converting the lists.

    config :my_app, MyApp.Vault,
      json_library: Jason

## Migration

The database field must be of type `:binary`.

    add :encrypted_field, :binary

## Usage

Define an `Encrypted.IntegerList` module in your project:

    defmodule MyApp.Encrypted.IntegerList do
      use Cloak.Ecto.IntegerList, vault: MyApp.Vault
    end

Then, define the type of your desired fields:

    schema "table_name" do
      field :encrypted_field, MyApp.Encrypted.IntegerList
    end