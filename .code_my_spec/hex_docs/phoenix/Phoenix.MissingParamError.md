# Phoenix.MissingParamError

Raised when a key is expected to be present in the request parameters,
but is not.

This exception is raised by `Phoenix.Controller.scrub_params/2` which:

  * Checks to see if the required_key is present (can be empty)
  * Changes all empty parameters to nils ("" -> nil)

If you are seeing this error, you should handle the error and surface it
to the end user. It means that there is a parameter missing from the request.