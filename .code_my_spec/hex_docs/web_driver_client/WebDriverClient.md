# WebDriverClient

Webdriver API client.

## start_session/2

Starts a new session

## fetch_sessions/1

Returns the list of sessions

## end_session/1

Ends a session

## navigate_to/2

Navigates the browser to the given url

## fetch_current_url/1

Returns the web browsers current url

## fetch_title/1

Returns page title of the top-most window.

This is the equivalent of calling `document.title`.

## fetch_page_source/1

Returns page source of the top-most window.

## fetch_window_size/1

Returns the size of the current window

## find_element/3

Finds the first element using the given search strategy

If no element is found, a `WebDriverClient.WebDriverError`
is returned

## find_elements/3

Finds the elements using the given search strategy

## find_elements_from_element/4

Finds elements that are children of the given element

## fetch_active_element/1

Fetches the currently active (focused) element

## set_window_size/2

Sets the size of the window

## fetch_log_types/1

Fetches the log types from the server

## fetch_logs/2

Fetches log entries for the requested log type.

## fetch_element_displayed/2

Sends a request to the server to see if an element
is displayed

## fetch_element_attribute/3

Fetches the value of an element's attribute

## fetch_element_property/3

Fetches the value of an element's property

Only supported using `:w3c` protocol.

## fetch_element_text/2

Fetches the visitble text of an element

## click_element/2

Clicks an element

## clear_element/2

Clears the value of a text input or text area element

## send_keys_to_element/3

Sends a sequence of keystrokes to an element

## send_keys/2

Sends a sequence of keystrokes to the currently active element.

Only supported with `:jwp` protocol. Prefer `send_keys_to_element/3` for
improved compatibility.

## fetch_alert_text/1

Fetches the text from the currently active alert.

## accept_alert/1

Accepts the currently active alert dialog.

Usually this is the equivalent to clicking ok on a dialog.

## dismiss_alert/1

Dismisses the currently active alert dialog.

For `confirm()` and `prompt()` dialogs, this is equivalent to
clicking the 'Cancel' button. For `alert()` dialogs, this is
equivalent to clicking the 'OK' button.

## send_alert_text/2

Sends keystrokes to the currently active Javascript `prompt` dialog.

## take_screenshot/1

Takes a screenshot of the current page.

## fetch_cookies/1

Fetches all cookies visible to the current web page.

## set_cookie/4

Sets a cookie

## delete_cookies/1

Deletes all cookies visible to the current page

## fetch_server_status/1

Fetches server status