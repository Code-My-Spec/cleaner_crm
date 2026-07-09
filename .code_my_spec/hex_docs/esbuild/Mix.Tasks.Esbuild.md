# Mix.Tasks.Esbuild

Invokes esbuild with the given args.

Usage:

    $ mix esbuild TASK_OPTIONS PROFILE ESBUILD_ARGS

Example:

    $ mix esbuild default assets/js/app.js --bundle --minify --target=es2016 --outdir=priv/static/assets

If esbuild is not installed, it is automatically downloaded.
Note the arguments given to this task will be appended
to any configured arguments.

## Options

  * `--runtime-config` - load the runtime configuration
    before executing command

Note flags to control this Mix task must be given before the
profile:

    $ mix esbuild --runtime-config default assets/js/app.js