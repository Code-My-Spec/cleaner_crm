# Swoosh.Email

Defines an Email.

This module defines a `Swoosh.Email` struct and the main functions for composing an email.  As it is the contract for
the public APIs of Swoosh it is a good idea to make use of these functions rather than build the struct yourself.

## Email fields

* `from` - the email address of the sender, example: `{"Tony Stark", "tony.stark@example.com"}`
* `to` - the email address for the recipient(s), example: `[{"Steve Rogers", "steve.rogers@example.com"}]`
* `subject` - the subject of the email, example: `"Hello, Avengers!"`
* `cc` - the intended carbon copy recipient(s) of the email, example: `[{"Bruce Banner", "hulk.smash@example.com"}]`
* `bcc` - the intended blind carbon copy recipient(s) of the email, example: `[{"Janet Pym", "wasp.avengers@example.com"}]`
* `text_body` - the content of the email in plaintext, example: `"Hello"`
* `html_body` - the content of the email in HTML, example: `"<h1>Hello</h1>"`
* `reply_to` - the email address that should receive replies, example: `{"Clint Barton", "hawk.eye@example.com"}`
* `headers` - a map of headers that should be included in the email, example: `%{"X-Accept-Language" => "en-us, en"}`
* `attachments` - a list of attachments that should be included in the email, example: `[%{path: "/data/uuid-random", filename: "att.zip", content_type: "application/zip"}]`
* `assigns` - a map of values that correspond with any template variables, example: `%{"first_name" => "Bruce"}`

## Private

This key is reserved for use with adapters, libraries and frameworks.

* `private` - a map of values that are for use by libraries/frameworks, example: `%{phoenix_template: "welcome.html.eex"}`
  - `client_options` will be passed to underlying http client post call

## Provider options

This key allow users to make use of provider-specific functionality by passing along addition parameters.

* `provider_options` - a map of values that are specific to adapter provider, example: `%{async: true}`

## Examples

    email =
      new()
      |> to("tony.stark@example.com")
      |> from("bruce.banner@example.com")
      |> text_body("Welcome to the Avengers")

The composable nature makes it very easy to continue expanding upon a given Email.

    email =
      email
      |> cc({"Steve Rogers", "steve.rogers@example.com"})
      |> cc("wasp.avengers@example.com")
      |> bcc(["thor.odinson@example.com", {"Henry McCoy", "beast.avengers@example.com"}])
      |> html_body("<h1>Special Welcome</h1>")

You can also directly pass arguments to the `new/1` function.

    email = new(from: "tony.stark@example.com", to: "steve.rogers@example.com", subject: "Hello, Avengers!")

## from/2

Sets a recipient in the `from` field.

## Examples

    iex> new() |> from({"Steve Rogers", "steve.rogers@example.com"})
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [], cc: [], from: {"Steve Rogers", "steve.rogers@example.com"},
     headers: %{}, html_body: nil, private: %{}, provider_options: %{},
     reply_to: nil, subject: "", text_body: nil, to: []}

    iex> new() |> from("steve.rogers@example.com")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [], cc: [], from: {"", "steve.rogers@example.com"},
     headers: %{}, html_body: nil, private: %{}, provider_options: %{},
     reply_to: nil, subject: "", text_body: nil, to: []}

## reply_to/2

Sets a recipient in the `reply_to` field. May also set a list of recipients as `reply_to`, but the
support for it on adapters is on case-by-case basis.

## Examples

    iex> new() |> reply_to({"Steve Rogers", "steve.rogers@example.com"})
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [], cc: [], from: nil,
     headers: %{}, html_body: nil, private: %{}, provider_options: %{},
     reply_to: {"Steve Rogers", "steve.rogers@example.com"}, subject: "", text_body: nil, to: []}

    iex> new() |> reply_to("steve.rogers@example.com")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [], cc: [], from: nil,
     headers: %{}, html_body: nil, private: %{}, provider_options: %{},
     reply_to: {"", "steve.rogers@example.com"}, subject: "", text_body: nil, to: []}

    iex> new() |> reply_to([{"Steve Rogers", "steve.rogers@example.com"}, "bucky.barnes@example.com"])
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [], cc: [], from: nil,
     headers: %{}, html_body: nil, private: %{}, provider_options: %{},
     reply_to: [{"Steve Rogers", "steve.rogers@example.com"}, {"", "bucky.barnes@example.com"}],
     subject: "", text_body: nil, to: []}

## subject/2

Sets the `subject` field.

The subject must be a string that contains the subject.

## Examples

    iex> new() |> subject("Hello, Avengers!")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [],
     cc: [], from: nil, headers: %{}, html_body: nil,
     private: %{}, provider_options: %{}, reply_to: nil, subject: "Hello, Avengers!",
     text_body: nil, to: []}

## text_body/2

Sets the `text_body` field.

The text body must be a string that containing the plaintext content.

## Examples

    iex> new() |> text_body("Hello")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [],
     cc: [], from: nil, headers: %{}, html_body: nil,
     private: %{}, provider_options: %{}, reply_to: nil, subject: "",
     text_body: "Hello", to: []}

## html_body/2

Sets the `html_body` field.

The HTML body must be a string that containing the HTML content.

## Examples

    iex> new() |> html_body("<h1>Hello</h1>")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [],
     cc: [], from: nil, headers: %{}, html_body: "<h1>Hello</h1>",
     private: %{}, provider_options: %{}, reply_to: nil, subject: "",
     text_body: nil, to: []}

## bcc/2

Adds new recipients in the `bcc` field.

    iex> new() |> bcc("steve.rogers@example.com")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [{"", "steve.rogers@example.com"}],
     cc: [], from: nil, headers: %{}, html_body: nil,
     private: %{}, provider_options: %{}, reply_to: nil, subject: "",
     text_body: nil, to: []}

## put_bcc/2

Puts new recipients in the `bcc` field.

It will replace any previously added `bcc` recipients.

## cc/2

Adds new recipients in the `cc` field.

## Examples

    iex> new() |> cc("steve.rogers@example.com")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [],
     cc: [{"", "steve.rogers@example.com"}], from: nil, headers: %{}, html_body: nil,
     private: %{}, provider_options: %{}, reply_to: nil, subject: "",
     text_body: nil, to: []}

## put_cc/2

Puts new recipients in the `cc` field.

It will replace any previously added `cc` recipients.

## to/2

Adds new recipients in the `to` field.

## Examples

    iex> new() |> to("steve.rogers@example.com")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [],
     cc: [], from: nil, headers: %{}, html_body: nil,
     private: %{}, provider_options: %{}, reply_to: nil, subject: "",
     text_body: nil, to: [{"", "steve.rogers@example.com"}]}

## put_to/2

Puts new recipients in the `to` field.

It will replace any previously added `to` recipients.

## header/3

Adds a new `header` in the email.

The name and value must be specified as strings.

## Examples

    iex> new() |> header("X-Magic-Number", "7")
    %Swoosh.Email{assigns: %{}, attachments: [], bcc: [], cc: [], from: nil,
     headers: %{"X-Magic-Number" => "7"}, html_body: nil, private: %{},
     provider_options: %{}, reply_to: nil, subject: "", text_body: nil, to: []}