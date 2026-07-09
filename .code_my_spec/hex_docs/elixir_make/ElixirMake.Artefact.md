# ElixirMake.Artefact



## cache_dir/0

Returns user cache directory.

## checksum_algo/0

Returns the checksum algorithm

## checksum/2

Computes the checksum and artefact for the given contents.

## write_checksum_for_target!/1

Writes checksum for the target to disk.

## write_checksums!/1

Writes checksums to disk.

## archive_path/3

Returns the full path to the precompiled archive.

## compress/2

Compresses the given files and computes its checksum and artefact.

## verify_and_decompress/2

Verifies and decompresses the given `archive_path` at `app_priv`.

## available_target_urls/2

Returns all available {{target, nif_version}, url} pairs available.

## current_target_url/3

Returns the url for the current target.