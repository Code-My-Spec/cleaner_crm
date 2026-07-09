# Phoenix.Digester



## compile/3

Digests and compresses the static files in the given `input_path`
and saves them in the given `output_path`.

## clean/4

Deletes compiled/compressed asset files that are no longer in use based on
the specified criteria.

## Arguments

  * `path` - The path where the compiled/compressed files are saved
  * `age` - The max age of assets to keep in seconds
  * `keep` - The number of old versions to keep

## clean_all/1

Deletes compiled/compressed asset files, including the cache manifest.

## Arguments

  * `path` - The path where the compiled/compressed files are saved