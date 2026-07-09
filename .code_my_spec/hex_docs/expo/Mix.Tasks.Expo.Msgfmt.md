# Mix.Tasks.Expo.Msgfmt

Generate binary message catalog from textual message description.

    mix expo.msgfmt [PO_FILE] [OPTIONS]

## Options

* `--use-fuzzy` - use fuzzy entries in output
* `--endianness=BYTEORDER` - write out 32-bit numbers in the given byte
  order (big or little, default depends on platform)
* `--output-file=FILE` - write output to specified file
* `--statistics` - print statistics about messages