# Swoosh.Adapter



## validate_config/2

Delivers multiple emails with the given config in one request. Some email providers allow multiple
messages to be sent in one HTTP request, for example Mailjet and Postmark allow this. Check your
provider's documentation to see if that is possible, and see the adapter you use to find out whether
it has been implemented.