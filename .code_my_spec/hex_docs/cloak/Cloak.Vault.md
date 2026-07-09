# Cloak.Vault

Encrypts and decrypts data, using a configured cipher.

## Create Your Vault

Define a module in your application that uses `Cloak.Vault`.

    defmodule MyApp.Vault do
      use Cloak.Vault, otp_app: :my_app
    end

## Configuration

The `:otp_app` option should point to an OTP application that has the vault
configuration.

For example, the vault:

    defmodule MyApp.Vault do
      use Cloak.Vault, otp_app: :my_app
    end

Could be configured with Mix configuration like so:

    config :my_app, MyApp.Vault,
      json_library: Jason,
      ciphers: [
        default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: <<...>>}
      ]

The configuration options are:

- `:json_library`: Used to convert data types like lists and maps into
  binary so that they can be encrypted. (Default: `Jason`)

- :ciphers: a list of `Cloak.Cipher` modules the following format:

        {:label, {CipherModule, opts}}

  **The first configured cipher in the list is the default for encrypting
  all new data, regardless of its label.** This behaviour can be overridden
  on a field-by-field basis.

  The `opts` are specific to each cipher module. Check their
  codumentation for what each cipher requires.

    - `Cloak.Ciphers.AES.GCM`
    - `Cloak.Ciphers.AES.CTR`

### Runtime Configuration

Because Vaults are GenServers, they can be configured at runtime using the
`init/1` callback. This allows you to easily fetch values like environment
variables in a reliable way.

The configuration from the `:otp_app` is passed as the first argument to the
callback, allowing you to append to or change it at will.

    defmodule MyApp.Vault do
      use Cloak.Vault, otp_app: :my_app

      @impl GenServer
      def init(config) do
        config =
          Keyword.put(config, :ciphers, [
            default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: decode_env!("CLOAK_KEY")}
          ])

        {:ok, config}
      end

      defp decode_env!(var) do
        var
        |> System.get_env()
        |> Base.decode64!()
      end
    end

You can also pass configuration to vaults via `start_link/1`:

    MyApp.Vault.start_link(ciphers: [
      default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: key}
    ])

## Supervision

Because Vaults are `GenServer`s, you'll need to add your vault to your
supervision tree in `application.ex` or whichever supervisor you prefer.

    children = [
      MyApp.Vault
    ]

If you want to pass in configuration values at runtime, you can do so:

    children = [
      {MyApp.Vault, ciphers: [...]}
    ]

## Usage

You can use the vault directly by calling its functions.

    MyApp.Vault.encrypt("plaintext")
    # => {:ok, <<...>>}

    MyApp.Vault.decrypt(ciphertext)
    # => {:ok, "plaintext"}

See the documented callbacks below for the functions you can call.

### Performance Notes

Vaults are not bottlenecks. They simply store configuration in an ETS table
named after the Vault, e.g. `MyApp.Vault.Config`. All encryption and
decryption is performed in your local process, reading configuration from
the vault's ETS table.

## __using__/1

The JSON library the vault uses to convert maps and lists into
JSON binaries before encryption.