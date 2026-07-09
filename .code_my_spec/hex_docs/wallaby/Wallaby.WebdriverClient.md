# Wallaby.WebdriverClient



## create_session/2

Create a session with the base url.

## delete_session/1

Deletes a session with the driver.

## find_elements/2

Finds an element on the page for a session. If an element is provided then
the query will be scoped to within that element.

## set_value/2

Sets the value of an element.

## clear/1

Clears the value in an element

## accept_alert/2

Invoked to accept one alert triggered within `open_dialog_fn` and return the alert message.

## dismiss_alert/2

Invoked to accept one alert triggered within `open_dialog_fn` and return the alert message.

## click/1

Clicks an element.

## click/2

Clicks given mouse button on the current cursor position.

## double_click/1

Double-clicks left mouse button at the current mouse coordinates.

## button_down/2

Clicks and holds the given mouse button at the current mouse coordinates.

## button_up/2

Releases given previously held mouse button.

## move_mouse_to/4

Move the mouse by an offset of the specified element.
If no element is specified, the move is relative to the current mouse cursor.
If an element is provided but no offset, the mouse will be moved to the center of the element.

Gets keyword list with element, xoffset and yoffset specified as an argument.

## touch_down/4

Touches the screen at the given position.

## touch_up/1

Stops touching the screen.

## tap/1

Taps the element.

## touch_move/3

Moves the touch pointer (finger, stylus etc.) on the screen to the point determined by the given coordinates.

## touch_scroll/3

Scroll on the screen from the given element by the given offset using touch events.

## text/1

Gets the text for an element.

## page_title/1

Gets the title of the current page.

## attribute/2

Gets the value of an elements attribute.

## visit/2

Visit a specific page.

## current_url/1

Gets the current url.

## current_path/1

Gets the current path or nil.

## selected/1

Gets the selected value of the element.

For Checkboxes and Radio buttons it returns the selected option.
For options selects it returns the selected option

## displayed/1

Checks if the element is being displayed.

## size/1

Gets the size of a element.

## rect/1

Gets the height, width, x, and y position of an Element.

## take_screenshot/1

Takes a screenshot.

## cookies/1

Gets the cookies for a session.

## set_cookie/4

Sets a cookie for the session.

It accepts a list of optional cookie attributes per the
[WebDriver specification](https://www.w3.org/TR/webdriver1/#cookies):

* path (string)
* domain (string)
* secure (boolean)
* httpOnly (boolean)
* expiry (integer; number of seconds since Unix Epoch)

## set_window_size/3

Sets the size of the window

## get_window_size/1

Gets the size of the window

## set_window_position/3

Changes the position of the window

## get_window_position/1

Gets the position of the window

## maximize_window/1

Maximizes the window if not already maximized

## execute_script/3

Executes JavaScript synchronously, taking as arguments the script to execute,
and optionally a list of arguments available in the script via `arguments`

## execute_script_async/3

Executes asynchronous JavaScript, taking as arguments the script to execute,
and optionally a list of arguments available in the script via `arguments`

## send_keys/2

Sends a list of key strokes to active element.

## log/1

Retrieves logs from the browser

## page_source/1

Retrieves the current page source from session

## window_handles/1

Retrieves the list of window handles of all windows (or tabs) available to the session

## window_handle/1

Retrieves the window handle for the currently focused window (or tab) for the session

## focus_window/2

Changes focus to another window (or tab)

You may specify the the window by its server-assigned window handle
or by the value of its name attribute.

## close_window/1

Closes the currently focused window (or tab)

## focus_frame/2

Changes focus to another frame

You may specify the the frame by passing the frame Element, its index or id.
When passed `nil`, the server should switch to the page's default (top level) frame.

## focus_parent_frame/1

Changes focus to parent frame

## element_size/1

Returns a tuple `{width, height}` with the size of the given element.

## element_location/1

Returns a tuple `{x, y}` with the coordinates of the top-left corner of given element.