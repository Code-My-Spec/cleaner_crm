# Mix.Tasks.Phx.Digest

Digests and compresses static files.

    $ mix phx.digest
    $ mix phx.digest priv/static -o /www/public

The first argument is the path where the static files are located. The
`-o` option indicates the path that will be used to save the digested and
compressed files.

If no path is given, it will use `priv/static` as the input and output path.

The output folder will contain:

  * the original file
  * the file compressed with gzip
  * a file containing the original file name and its digest
  * a compressed file containing the file name and its digest
  * a cache manifest file

Example of generated files:

  * app.js
  * app.js.gz
  * app-eb0a5b9302e8d32828d8a73f137cc8f0.js
  * app-eb0a5b9302e8d32828d8a73f137cc8f0.js.gz
  * cache_manifest.json

You can use `mix phx.digest.clean` to prune stale versions of the assets.
If you want to remove all produced files, run `mix phx.digest.clean --all`.

## vsn

It is possible to digest the stylesheet asset references without the query
string "?vsn=d" with the option `--no-vsn`.

## Options

  * `-o, --output` - indicates the path to your compiled
    assets directory. Defaults to `priv/static`

  * `--no-vsn` - do not add version query string to assets

  * `--no-compile` - do not run mix compile