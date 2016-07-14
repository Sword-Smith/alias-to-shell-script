# alias-to-shell-script
##Automatically convert aliases to shell scripts

This script reads your .bashrc file and creates scripts from the alias definitions found. It only recognizes aliases that begin at the start of a line so any indented aliases (perhaps located inside if clauses) will not be made into scripts.

##WARNING
This script does not check for recursion but it expands the commands on the right hand side of the alias definition to try to avoid fork bombs. Whether this actually works in all cases has not been tested. So beware. A fork bomb may make your OS unstable and it might even require a reinstallation of your OS.

For this reason, the program can be run in dryrun mode to show its output. It is recommended that this output is checked before the program is run with the --execute option.

##Motivation

By making scripts from aliases, the user can use the same shortening of bash commands as arguments to the command xargs as the user otherwise does. Assuming that `ga` is defined as `git add`, the user can use the following command to add files interactively: `git diff --name-only | xargs -n 1 -p ga`.