# The theme module's path is only known at run time, so `use` cannot be
# checked here.
#
# nu-lint-ignore-file: dynamic_script_import, string_may_be_bare
# The module resolves only where it is installed, so a clean checkout
# cannot parse the `use` or anything it exports.
# nu-lint-ignore-file: nu_parse_error
# catch_builtin_error_try: the path `open` is given is a store path
# substituted at build time, so a failure there means a broken
# activation and has to be loud rather than caught.
# nu-lint-ignore-file: catch_builtin_error_try

# `watch` applies the matching variant and installs a pre_prompt hook,
# gated on the mtime of .GlobalPreferences.plist so an ordinary prompt
# costs nothing. It also repoints STARSHIP_CONFIG, overriding what
# programs.starship exports, so the prompt and the shell cannot
# disagree.
#
# `use` needs a path it can resolve at parse time, hence the symlink
# rather than the working copy inline.
use ($nu.default-config-dir | path join "dracula-pro.nu") *
watch --themes (open '@themeDirs@')
