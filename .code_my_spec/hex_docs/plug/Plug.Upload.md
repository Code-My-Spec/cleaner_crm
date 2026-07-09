# Plug.Upload

A server (a `GenServer` specifically) that manages uploaded files.

Uploaded files are stored in a temporary directory
and removed from that directory after the process that
requested the file dies.

During the request, files are represented with
a `Plug.Upload` struct that contains three fields:

  * `:path` - the path to the uploaded file on the filesystem
  * `:content_type` - the content type of the uploaded file
  * `:filename` - the filename of the uploaded file given in the request

**Note**: as mentioned in the documentation for `Plug.Parsers`, the `:plug`
application has to be started in order to upload files and use the
`Plug.Upload` module.

## Security

The `:content_type` and `:filename` fields in the `Plug.Upload` struct are
client-controlled. These values should be validated, via file content
inspection or similar, before being trusted.

## random_file/1

Requests a random file to be created in the upload directory
with the given prefix.

## delete/1

Deletes the given upload file.

Uploads are automatically removed when the current process terminates,
but you may invoke this to request the file to be removed sooner.

## give_away/3

Assign ownership of the given upload file to another process.

Useful if you want to do some work on an uploaded file in another process
since it means that the file will survive the end of the request.

## random_file!/1

Requests a random file to be created in the upload directory
with the given prefix. Raises on failure.