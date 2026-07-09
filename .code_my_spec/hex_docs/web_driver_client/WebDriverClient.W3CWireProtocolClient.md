# WebDriverClient.W3CWireProtocolClient



## start_session/2

Starts a new session

Specification: https://w3c.github.io/webdriver/#new-session-0

## fetch_sessions/1

Returns the list of currently active sessions

This isn't part of the official W3C spec

## end_session/1

End the session.

Specification: https://w3c.github.io/webdriver/#delete-session

## navigate_to/2

Navigate to a new URL

Specification: https://w3c.github.io/webdriver/#navigate-to

## fetch_current_url/1

Fetches the current url of the top-level browsing context.

Specification: https://w3c.github.io/webdriver/#get-current-url

## fetch_title/1

Fetches the document title of the top-level browsing context.

Specification: https://w3c.github.io/webdriver/#get-title

## fetch_page_source/1

Fetches the page source of the top-level browsing context.

Specification: https://w3c.github.io/webdriver/#get-page-source

## fetch_logs/2

Fetches the log for a given type.

This function is not part of the official spec and is
not supported by all servers.

## find_element/3

Finds the first element using the given search strategy.

If no elements are found, a `WebDriverError` is returned.

Specification: https://w3c.github.io/webdriver/#find-element

## find_elements/3

Finds the elements using the given search strategy

Specification: https://w3c.github.io/webdriver/#find-elements

## find_elements_from_element/4

Finds the elements that are children of the given element

Specification: https://w3c.github.io/webdriver/#find-elements-from-element

## fetch_active_element/1

Fetches the currently active element

Specification: https://w3c.github.io/webdriver/#get-active-element

## fetch_element_displayed/2

Sends a request to the server to see if an element
is displayed

Specification: https://w3c.github.io/webdriver/#element-displayedness

## fetch_element_attribute/3

Fetches the value of an element's attribute

Specification: https://w3c.github.io/webdriver/#get-element-attribute

## fetch_element_property/3

Fetches the value of an element's property

Specification: https://w3c.github.io/webdriver/#get-element-property

## fetch_element_text/2

Fetches an elements visible text

Specification: https://w3c.github.io/webdriver/#get-element-text

## click_element/2

Clicks an element

Specification: https://w3c.github.io/webdriver/#element-click

## clear_element/2

Clears a resettable or content editable element

Specification: https://w3c.github.io/webdriver/#element-clear

## send_keys_to_element/3

Send keystrokes to an element

Specification: https://w3c.github.io/webdriver/#element-send-keys

## fetch_alert_text/1

Fetches the text of the current alert

Specification: https://w3c.github.io/webdriver/#get-alert-text

## send_alert_text/2

Sets the text field of a `window.prompt()` dialog to the given value

Specification: https://w3c.github.io/webdriver/#send-alert-text

## accept_alert/1

Accepts the currently active alert dialog.

Specification: https://w3c.github.io/webdriver/#accept-alert

## dismiss_alert/1

Dismisses the currently active alert dialog.

Specification: https://w3c.github.io/webdriver/#dismiss-alert

## take_screenshot/1

Takes a screenshot of the current page

Specification: https://w3c.github.io/webdriver/#take-screenshot

## fetch_cookies/1

Fetches the cookies visible to the current page

Specification: https://w3c.github.io/webdriver/#get-all-cookies

## set_cookie/4

Sets a cookie

Specification: https://w3c.github.io/webdriver/#add-cookie

## delete_cookies/1

Deletes all cookies for the current page

Specification: https://w3c.github.io/webdriver/#delete-all-cookies

## fetch_server_status/1

Fetches the server status

Specification: https://w3c.github.io/webdriver/#status