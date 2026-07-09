# Mix.Tasks.Sobelow

Sobelow is a static analysis tool for discovering
vulnerabilities in Phoenix applications.

This tool should be run in the root of the project directory
with the following command:

    mix sobelow

## Command line options

* `--root -r` - Specify application root directory
* `--verbose -v` - Print vulnerable code snippets
* `--ignore -i` - Ignore modules
* `--ignore-files` - Ignore files
* `--details -d` - Get module details
* `--all-details` - Get all module details
* `--private` - Skip update checks
* `--strict` - Exit when bad syntax is encountered
* `--mark-skip-all` - Mark all printed findings as skippable
* `--clear-skip` - Clear configuration added by `--mark-skip-all`
* `--skip` - Skip functions flagged with `#sobelow_skip` or tagged with `--mark-skip-all`
* `--router` - Specify router location
* `--exit` - Return non-zero exit status
* `--threshold` - Only return findings at or above a given confidence level
* `--format` - Specify findings output format
* `--quiet` - Return no output if there are no findings
* `--compact` - Minimal, single-line findings
* `--save-config` - Generates a configuration file based on command line options
* `--[no-]config` - Run Sobelow with or without the configuration file.
* `--version` - Output current version of Sobelow

## Ignoring modules

If specific modules, or classes of modules are not relevant
to the scan, it is possible to ignore them with a
comma-separated list.

    mix sobelow -i XSS.Raw,Traversal

## Supported modules

* XSS
* XSS.Raw
* XSS.SendResp
* XSS.ContentType
* XSS.HTML
* SQL
* SQL.Query
* SQL.Stream
* Config
* Config.CSRF
* Config.Headers
* Config.CSP
* Config.HTTPS
* Config.HSTS
* Config.Secrets
* Config.CSWH
* Vuln
* Vuln.CookieRCE
* Vuln.HeaderInject
* Vuln.PlugNull
* Vuln.Redirect
* Vuln.Coherence
* Vuln.Ecto
* Traversal
* Traversal.SendFile
* Traversal.FileModule
* Traversal.SendDownload
* Misc
* Misc.BinToTerm
* Misc.FilePath
* RCE.EEx
* RCE.CodeModule
* CI
* CI.System
* CI.OS
* DOS
* DOS.StringToAtom
* DOS.ListToAtom
* DOS.BinToAtom