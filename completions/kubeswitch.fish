# =============================================================================
# fish-kubeswitch | Copyright (C) 2021 eth-p
#
# A kubectx/kubens replacement that sets the kubectl config file, context, and
# namespace for each individual instance of the fish shell.
#
# Documentation: https://github.com/eth-p/fish-kubeswitch/tree/master/docs
# Repository:    https://github.com/eth-p/fish-kubeswitch
# Issues:        https://github.com/eth-p/fish-kubeswitch/issues
# =============================================================================
complete -c "kubeswitch" -e

# Completions for selecting a subcommand.
complete -c "kubeswitch" -f \
	-n "not __fish_seen_subcommand_from (kubeswitch --complete-list-subcommands)" \
	-a '(kubeswitch --complete-list-subcommands --complete-suggestions)'

# Completions for the 'config' subcommand.
complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands config)" \
	-a '(kubeswitch config --complete-suggestions)'

complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands config)" \
	-s 'c' -l 'current' -d 'Show the current config file'

complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands config)" \
	-s 'L' -l 'list' -d 'List the available config files'

# Completions for the 'context' subcommand.
complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands context)" \
	-a '(kubeswitch context --complete-suggestions)'

complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands context)" \
	-s 'c' -l 'current' -d 'Show the current context'

complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands context)" \
	-s 'L' -l 'list' -d 'List the available contexts'

# Completions for the 'namespace' subcommand.
complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands namespace)" \
	-a '(kubeswitch namespace --complete-suggestions)'

complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands namespace)" \
	-s 'c' -l 'current' -d 'Show the current namespace'

complete -c "kubeswitch" -f \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands namespace)" \
	-s 'L' -l 'list' -d 'List the available namespaces'

# Completions for the 'kubectl' subcommand.
complete -c "kubeswitch" -f -k \
	-n "__fish_seen_subcommand_from (kubeswitch --complete-list-subcommands kubectl)" \
	-a '(complete --do-complete (commandline -p | cut -d" " -f 2-))'
