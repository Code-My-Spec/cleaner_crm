# Wallaby

A concurrent feature testing library.

## Configuration

Wallaby supports the following options:

* `:otp_app` - The name of your OTP application. This is used to check out your Ecto repos into the SQL Sandbox.
* `:screenshot_dir` - The directory to store screenshots.
* `:screenshot_on_failure` - if Wallaby should take screenshots on test failures (defaults to `false`).
* `:max_wait_time` - The amount of time that Wallaby should wait to find an element on the page. (defaults to `3_000`)
* `:js_errors` - if Wallaby should re-throw JavaScript errors in elixir (defaults to true).
* `:js_logger` - IO device where JavaScript console logs are written to. Defaults to :stdio. This option can also be set to a file or any other io device. You can disable JavaScript console logging by setting this to `nil`.

## start_session/1

Starts a browser session.

## Multiple sessions

Each session runs in its own browser so that each test runs in isolation.
Because of this isolation multiple sessions can be created for a test:

```
@message_field Query.text_field("Share Message")
@share_button Query.button("Share")
@message_list Query.css(".messages")

test "That multiple sessions work" do
  {:ok, user1} = Wallaby.start_session
  user1
  |> visit("/page.html")
  |> fill_in(@message_field, with: "Hello there!")
  |> click(@share_button)

  {:ok, user2} = Wallaby.start_session
  user2
  |> visit("/page.html")
  |> fill_in(@message_field, with: "Hello yourself")
  |> click(@share_button)

  assert user1 |> find(@message_list) |> List.last |> text == "Hello yourself"
  assert user2 |> find(@message_list) |> List.first |> text == "Hello there"
end
```

## end_session/1

Ends a browser session.