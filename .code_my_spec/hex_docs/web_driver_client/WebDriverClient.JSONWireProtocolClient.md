# WebDriverClient.JSONWireProtocolClient



## start_session/2

Starts a new session

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-session

## fetch_sessions/1

Returns the list of currently active sessions

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessions

## end_session/1

End the session.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#delete-sessionsessionid

## navigate_to/2

Navigate to a new URL

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidurl

## fetch_current_url/1

Fetches the url of the current page.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidurl

## fetch_title/1

Fetches the title of the current page.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidtitle

## fetch_page_source/1

Fetches the page source of the current page.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidtitle

## find_element/3

Finds the first element using the given search strategy.

If no elements are found, a `WebDriverError` is returned.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelement

## find_elements/3

Finds the elements using the given search strategy

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelements

## find_elements_from_element/4

Finds elements that are children of the given element

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidelements

## fetch_active_element/1

Fetches the currently active (focused) element

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementactive

## fetch_log_types/1

Fetches the available log types.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidlogtypes

## fetch_logs/2

Fetches the log for a given type.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidlog

## fetch_element_displayed/2

Sends a request to the server to see if an element
is displayed

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidelementiddisplayed

## fetch_element_attribute/3

Fetchs the attribute value of an element

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidelementidattributename

## fetch_element_text/2

Fetchess the visible text of an element

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidelementidtext

## click_element/2

Clicks an element

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidclick

## clear_element/2

Clear a TEXTAREA or text INPUT element's value.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidclear

## send_keys_to_element/3

Send a sequence of key strokes to an element

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidelementidvalue

## send_keys/2

Send a sequence of key strokes to the active element

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#sessionsessionidkeys

## fetch_alert_text/1

Fetches the text of the current alert.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidalert_text

## send_alert_text/2

Sends keystrokes to a JavaScript `prompt()` dialog.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidalert_text

## accept_alert/1

Accepts the currently active alert.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidaccept_alert

## dismiss_alert/1

Dismisses the currently active alert.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessioniddismiss_alert

## take_screenshot/1

Takes a screenshot of the current page

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidscreenshot

## fetch_cookies/1

Fetches all cookies visible to the current page.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-sessionsessionidcookie

## set_cookie/4

Sets a cookie.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#post-sessionsessionidcookie

## delete_cookies/1

Deletes all cookies visible to the current page.

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#delete-sessionsessionidcookie

## fetch_server_status/1

Fetches the current server status

Specification: https://github.com/SeleniumHQ/selenium/wiki/JsonWireProtocol#get-status