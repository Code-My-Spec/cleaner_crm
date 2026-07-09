# Mix.Tasks.Tailwind

Invokes tailwind with the given args.

Usage:

    $ mix tailwind TASK_OPTIONS PROFILE TAILWIND_ARGS

Example:

    $ mix tailwind default --minify --input=css/app.css       --output=../priv/static/assets/app.css 
If Tailwind is not installed, it is automatically downloaded.
Note the arguments given to this task will be appended
to any configured arguments.

If using Tailwind v3, you'd also pass the `--config=tailwind.config.js`
flag pointing to your Tailwind configuration. In Tailwind v4, the
configuration happens with the input CSS file.

## Options

  * `--runtime-config` - load the runtime configuration
    before executing command

Note flags to control this Mix task must be given before the
profile:

    $ mix tailwind --runtime-config default