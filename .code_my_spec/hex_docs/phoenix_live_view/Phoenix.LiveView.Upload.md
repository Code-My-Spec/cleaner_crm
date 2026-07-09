# Phoenix.LiveView.Upload



## allow_upload/3

Allows an upload.

## disallow_upload/2

Disallows a previously allowed upload.

## cancel_upload/3

Cancels an upload entry.

## maybe_cancel_uploads/1

Cancels all uploads that exist.

Returns a tuple containing the new socket and a list of the cancelled upload configs.

## update_upload_entry_meta/4

Updates the entry metadata.

## update_progress/4

Updates the entry progress.

Progress is either an integer percentage between 0 and 100, or a map
with an `"error"` key containing the information for a failed upload
while in progress on the client.

## put_entries/4

Puts the entries into the `%UploadConfig{}`.

## unregister_completed_entry_upload/3

Unregisters a completed entry from a `Phoenix.LiveView.UploadChannel` process.

## register_entry_upload/4

Registers a new entry upload for a `Phoenix.LiveView.UploadChannel` process.

## put_upload_error/4

Populates the errors for a given entry.

## get_upload_by_ref!/2

Retrieves the `%UploadConfig{}` from the socket for the provided ref or raises.

## get_upload_by_pid/2

Returns the `%UploadConfig{}` from the socket for the `Phoenix.LiveView.UploadChannel` pid.

## uploaded_entries/2

Returns the completed and in progress entries for the upload.

## consume_uploaded_entries/3

Consumes the uploaded entries or raises if entries are still in progress.

## consume_uploaded_entry/3

Consumes an individual entry or raises if it is still in progress.

## drop_upload_entries/3

Drops all entries from the upload.

## generate_preflight_response/4

Generates a preflight response by calling the `:external` function.