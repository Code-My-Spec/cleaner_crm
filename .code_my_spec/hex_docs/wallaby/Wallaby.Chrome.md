# Wallaby.Chrome

The Chrome driver uses [Chromedriver](https://chromedriver.chromium.org/) to power Google Chrome and Chromium.

## Usage

Start a Wallaby Session using this driver with the following command:

```elixir
{:ok, session} = Wallaby.start_session()
```

## Configuration

### Headless

Chrome will run in headless mode by default.
You can disable this behaviour using the following configuration.

This will override the default capabilities and capabilities set with application configuration.
This will _not_ override capabilities passed in directly to `Wallaby.start_session/1`.

```elixir
config :wallaby,
  chromedriver: [
    headless: false
  ]
```

### Capabilities

These capabilities will override the default capabilities.

```elixir
config :wallaby,
  chromedriver: [
    capabilities: %{
      # something
    }
  ]
```

### ChromeDriver binary

If ChromeDriver is not available in your path, you can specify it's location.

```elixir
config :wallaby,
  chromedriver: [
    path: "path/to/chrome"
  ]
```

### Chrome binary

This configures which instance of Google Chrome to use.

This will override the default capabilities and capabilities set with application configuration.
This will _not_ override capabilities passed in directly to `Wallaby.start_session/1`.

```elixir
config :wallaby,
  chromedriver: [
    binary: "path/to/chrome"
  ]
```

## Default Capabilities

By default, Chromedriver will use the following capabilities

You can read more about capabilities in the [JSON Wire Protocol](https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#capabilities-json-object) documentation and the [Chromedriver](https://sites.google.com/a/chromium.org/chromedriver/capabilities) documentation.

```elixir
  %{
    javascriptEnabled: false,
    loadImages: false,
    version: "",
    rotatable: false,
    takesScreenshot: true,
    cssSelectorsEnabled: true,
    nativeEvents: false,
    platform: "ANY",
    unhandledPromptBehavior: "accept",
    loggingPrefs: %{
      browser: "DEBUG"
    },
    chromeOptions: %{
      args: [
        "--no-sandbox",
        "window-size=1280,800",
        "--disable-gpu",
        "--headless",
        "--fullscreen",
        "--user-agent=Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36"
      ]
    }
  }
```

## Notes

This driver requires [Chromedriver](https://sites.google.com/a/chromium.org/chromedriver/) to be installed in your path.