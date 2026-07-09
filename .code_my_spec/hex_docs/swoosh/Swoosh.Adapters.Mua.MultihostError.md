# Swoosh.Adapters.Mua.MultihostError

Raised when no relay is used and recipients contain addresses across multiple hosts.

For example:

    email =
      Swoosh.Email.new(
        to: {"Mua", "mua@github.com"},
        cc: [{"Swoosh", "mua@swoosh.github.com"}]
      )

    Swoosh.Adapters.Mua.deliver(email, _no_relay_config = [])

Fields:

  - `:hosts` - the hosts for the recipients, `["github.com", "swoosh.github.com"]` in the example above