# Mix.Tasks.Phx.Digest.Clean

Removes old versions of compiled assets.

By default, it will keep the latest version and
2 previous versions as well as any digest created
in the last hour.

    $ mix phx.digest.clean
    $ mix phx.digest.clean -o /www/public
    $ mix phx.digest.clean --age 600 --keep 3
    $ mix phx.digest.clean --all

## Options

  * `-o, --output` - indicates the path to your compiled
    assets directory. Defaults to `priv/static`

  * `--age` - specifies a maximum age (in seconds) for assets.
    Files older than age that are not in the last `--keep` versions
    will be removed. Defaults to 3600 (1 hour)

  * `--keep` - specifies how many previous versions of assets to keep.
    Defaults to 2 previous versions

  * `--all` - specifies that all compiled assets (including the manifest)
    will be removed. Note this overrides the age and keep switches.

  * `--no-compile` - do not run mix compile