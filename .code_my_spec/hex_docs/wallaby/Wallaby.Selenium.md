# Wallaby.Selenium

The Selenium driver uses [Selenium Server](https://github.com/SeleniumHQ/selenium) to power many types of browsers (Chrome, Firefox, Edge, etc).

## Usage

Start a Wallaby Session using this driver with the following command:

```elixir
{:ok, session} = Wallaby.start_session()
```

## Configuration

### Capabilities

These capabilities will override the default capabilities.

```elixir
config :wallaby,
  selenium: [
    capabilities: %{
      # something
    }
  ]
```

### Selenium Remote URL

It is possible to globally set Selenium's "Remote URL" by setting the following option.

By default it is http://localhost:4444/wd/hub/

```elixir
config :wallaby,
  selenium: [
    remote_url: "http://selenium_url"
  ]
```

## Default Capabilities

By default, Selenium will use the following capabilities

You can read more about capabilities in the [JSON Wire Protocol](https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#capabilities-json-object) documentation.

```elixir
%{
  javascriptEnabled: true,
  browserName: "firefox",
  "moz:firefoxOptions": %{
    args: ["-headless"]
  }
}
```

## Notes

- Requires [selenium-server](https://www.seleniumhq.org/download/) to be running on port 4444. Wallaby does _not_ manage the start/stop of the Selenium server.
- Requires [GeckoDriver](https://github.com/mozilla/geckodriver) to be installed in your path when using [Firefox](https://www.mozilla.org/en-US/firefox/new/). Firefox is used by default.

## send_keys/2

Simulates typing into an element.

When sending keys to an element and `keys` is identified as
a local file, the local file is uploaded to the
Selenium server, returning a file path which is then
set to the file input we are interacting with.

We then call the `WebdriverClient.send_keys/2` to set the
remote file path as the input's value.