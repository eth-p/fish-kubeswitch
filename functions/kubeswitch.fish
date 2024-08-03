# =============================================================================
# fish-kubeswitch | Copyright (C) 2021-2024 eth-p
#
# A kubectx/kubens replacement that sets the kubectl config file, context, and
# namespace for each individual instance of the fish shell.
#
# Documentation: https://github.com/eth-p/fish-kubeswitch/tree/master/docs
# Repository:    https://github.com/eth-p/fish-kubeswitch
# Issues:        https://github.com/eth-p/fish-kubeswitch/issues
# =============================================================================

function kubeswitch --description="Change kubectx configuration for this fish instance"
	set -l _original_argv $argv
	argparse -i -x 'no-color,force-color' -x 'help,complete-list-subcommands' \
		'q/quiet' 'h/help' 'no-color' 'force-color' \
		'complete-list-subcommands' 'complete-suggestions' -- $argv || return 1

	# Handle --no-color or --force-color flag.
	set -g _KS_COLOR "false"
	if [ -n "$_flag_no_color" ]
		set _KS_COLOR "false"
	else if [ -n "$_flag_force_color" ]
		set _KS_COLOR "true"
	else if [ -t 1 ]
		set _KS_COLOR "true"
	end

	# Handle the --quiet flag.
	set -g _KS_QUIET "false"
	if [ -n "$_flag_quiet" ]
		set _KS_QUIET "true"
	end

	# Find the subcommand.
	set -l subcommand ''
	set -l args
	set -l arg
	for arg in $argv
		switch "$arg"
		case "-*"
			set --append args $arg

		case "*"
			if [ -z "$subcommand" ]
				set subcommand "$arg"
			else
				set --append args $arg
			end
		end
	end

	# Set the name of the subcommand.
	set -g _KS_SELF "$_"
	if [ "$_KS_SELF" = "kubeswitch" ] && [ -n "$subcommand" ]
		set _KS_SELF "$_ $subcommand"
	end

	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		if [ -z "$subcommand" ]
			__kubeswitch_help_kubeswitch
			return 0
		else
			set -a args "--help"
		end
	end

	# Handle the --complete-list-subcommands flag.
	if [ -n "$_flag_complete_list_subcommands" ]
		if [ -n "$_flag_complete_suggestions" ]
			printf "%s\t%s\n" \
				"config"    "Change the active kubeconfig file" \
				"context"   "Change the active kubeconfig context" \
				"namespace" "Change the current namespace" \
				"kubectl"   "Run kubectl" \
				"show"      "Show kubeswitch environment info"
		else
			set -l completions
			if [ "$subcommand" = "" ] || [ "$subcommand" = "config" ]
				set -a completions "config" "cfg" "kubeconfig" "kubefile" "kubecfg"
			end
			if [ "$subcommand" = "" ] || [ "$subcommand" = "context" ]
				set -a completions "context" "ctx" "kubectx"
			end
			if [ "$subcommand" = "" ] || [ "$subcommand" = "namespace" ]
				set -a completions "namespace" "ns" "kubens"
			end
			if [ "$subcommand" = "" ] || [ "$subcommand" = "kubectl" ]
				set -a completions "kubectl"
			end
			if [ "$subcommand" = "" ] || [ "$subcommand" = "kubectl-alias" ]
				set -a completions "kubectl-alias"
			end
			if [ "$subcommand" = "" ] || [ "$subcommand" = "inherit-env" ]
				set -a completions "inherit-env"
			end
			if [ "$subcommand" = "" ] || [ "$subcommand" = "show" ]
				set -a completions "show"
			end
			printf "%s\n" $completions
		end
		return 0
	end

	# Handle subcommands.
	set -l return_status 0
	switch "$subcommand"
	case "context" "ctx" "kubectx"
		__kubeswitch_subcmd_context $args $_flag_complete_suggestions
		set return_status $status

	case "config" "cfg" "kubeconfig" "kubefile" "kubecfg"
		__kubeswitch_subcmd_config $args $_flag_complete_suggestions
		set return_status $status

	case "namespace" "ns" "kubens"
		__kubeswitch_subcmd_namespace $args $_flag_complete_suggestions
		set return_status $status

	case "kubectl"
		__kubeswitch_subcmd_kubectl $_original_argv[2..-1]
		set return_status $status
	
	case "kubectl-alias"	
		__kubeswitch_subcmd_kubectl_alias $args
		set return_status $status

	case "inherit-env"
		__kubeswitch_subcmd_inherit_env $args
		set return_status $status

	case "wrapper-bin"
		__kubeswitch_subcommand_wrapper_bin $args
		set return_status $status

	case "show"
		__kubeswitch_subcmd_show $args
		set return_status $status

	case "help" ""
		__kubeswitch_help_kubeswitch
		set return_status 0
		return 0

	case "*"
		echo "kubeswitch: '$subcommand' is not a valid subcommand"
		set return_status 1
	end
	
	# Clean up and return.
	set -e _KS_SELF
	set -e _KS_COLOR
	set -e _KS_QUIET
	return $return_status
end

function __kubeswitch_update_inherit_env --on-event='kubeswitch' \
--description="Update the values inherited by kubeswitch inherit-env"
	set -U __kubeswitch_last_kubeconfig "$KUBECONFIG"
	set -U __kubeswitch_last_context    "$KUBESWITCH_CONTEXT"
	set -U __kubeswitch_last_namespace  "$KUBESWITCH_NAMESPACE"
end



# -----------------------------------------------------------------------------
# Help:
# -----------------------------------------------------------------------------

function __kubeswitch_help_kubeswitch --description="Show help for kubeswitch"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch"

	begin
		echo "SUBCOMMANDS:"
		echo "    $_KS_SELF config           : view or change the kubeconfig file"
		echo "    $_KS_SELF context          : view or change the active kubectl context"
		echo "    $_KS_SELF namespace        : view or change the active kubectl namespace"
		echo "    $_KS_SELF kubectl          : run kubectl within the kubeswitch environment"
		echo "    $_KS_SELF kubectl-alias    : create an alias for 'kubeswitch kubectl'"
		echo "    $_KS_SELF inherit-env      : inherit the kubeswitch environment"
		echo "    $_KS_SELF show             : show kubeswitch environment info"
		echo "    $_KS_SELF wrapper-bin      : generate a shell script that wraps the kubectl binary"
		echo ""
		echo "OPTIONS:"
		echo "    --no-color       : disable color output"
		echo "    --force-color    : force color output"
		echo ""
		echo "CONFIG:"
		echo "    \$kubeswitch_kubeconfig_path    : lookup path for kubeconfig files"
		echo "    \$kubeswitch_kubeconfig_exts    : extensions for kubeconfig files"
		echo "    \$kubeswitch_kubectl            : the kubectl command"
	end 1>&2
end

function __kubeswitch_help_kubeswitch_config --description="Show help for kubeswitch config"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch config"

	begin
		echo "View or change the configuration file used by 'kubeswitch kubectl'."
		echo ""
		echo "USAGE:"
		echo "    $_KS_SELF                  : list/change config files"
		echo "    $_KS_SELF <NAME>           : switch to the specified config file"
		echo "    $_KS_SELF -L, --list       : list the available config files"
		echo "    $_KS_SELF -c, --current    : show the current config file"
		echo "    $_KS_SELF -h, --help       : show this message"
		echo ""
		echo "CONFIG:"
		#echo "    \$kubeswitch_enable_fzf      : if set to false, fzf will not be used"
		echo "    \$kubeswitch_color_active    : the color of the active file/context/namespace"
	end 1>&2
end

function __kubeswitch_help_kubeswitch_context --description="Show help for kubeswitch context"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch context"

	begin
		echo "View or change the active context used by 'kubeswitch kubectl'."
		echo ""
		echo "USAGE:"
		echo "    $_KS_SELF                  : list/change contexts"
		echo "    $_KS_SELF <NAME>           : switch to the specified context"
		echo "    $_KS_SELF -L, --list       : list the available contexts"
		echo "    $_KS_SELF -c, --current    : show the current context"
		echo "    $_KS_SELF -h, --help       : show this message"
		echo ""
		echo "CONFIG:"
		#echo "    \$kubeswitch_enable_fzf      : if set to false, fzf will not be used"
		echo "    \$kubeswitch_color_active    : the color of the active file/context/namespace"
	end 1>&2
end

function __kubeswitch_help_kubeswitch_namespace --description="Show help for kubeswitch namespace"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch namespace"

	begin
		echo "View or change the active namespace used by 'kubeswitch kubectl'."
		echo ""
		echo "USAGE:"
		echo "    $_KS_SELF                  : list/change namespaces"
		echo "    $_KS_SELF <NAME>           : switch to the specified namespace"
		echo "    $_KS_SELF -L, --list       : list the available namespaces"
		echo "    $_KS_SELF -c, --current    : show the current namespace"
		echo "    $_KS_SELF -h, --help       : show this message"
		echo ""
		echo "CONFIG:"
		#echo "    \$kubeswitch_enable_fzf      : if set to false, fzf will not be used"
		echo "    \$kubeswitch_color_active    : the color of the active file/context/namespace"
	end 1>&2
end

function __kubeswitch_help_kubeswitch_kubectl_alias --description="Show help for kubeswitch kubectl-alias"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch kubectl-alias"

	begin
		echo "Create an alias to kubectl which runs within the kubeswitch environment."
		echo ""
		echo "USAGE:"
		echo "    $_KS_SELF <NAME>        : create an alias to kubectl with the name <NAME>"
		echo "    $_KS_SELF -h, --help    : show this message"
	end 1>&2
end

function __kubeswitch_help_kubeswitch_inherit_env --description="Show help for kubeswitch inherit-env"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch inherit-env"

	begin
		echo "Inherit the most-recently-set kubeswitch environment from another fish instance."
		echo ""
		echo "USAGE:"
		echo "    $_KS_SELF               : inherit the kubeswitch environment"
		echo "    $_KS_SELF -h, --help    : show this message"
	end 1>&2
end

function __kubeswitch_help_kubeswitch_show --description="Show help for kubeswitch show"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch show"

	begin
		echo "Show info about the kubeswitch environment."
		echo ""
		echo "USAGE:"
		echo "    $_KS_SELF                : show basic info in a human-readable format"
		echo "    $_KS_SELF --porcelain    : show info in a fish eval compatible format"
		echo "    $_KS_SELF --ksi          : extract user-defined metadata from the kubeswitch environment"
		echo "    $_KS_SELF -h, --help     : show this message"
	end 1>&2
end

function __kubeswitch_help_kubeswitch_wrapper_bin --description="Show help for kubeswitch wrapper-bin"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch show"

	begin
		echo "Generate a shell script that wraps the kubectl binary."
		echo ""
		echo "This allows external tools to use the kubeswitch context and namespace."
		echo "The shell script will be saved to ~/.local/bin/kubectl."
	end 1>&2
end




# -----------------------------------------------------------------------------
# Subcommands:
# -----------------------------------------------------------------------------

function __kubeswitch_subcmd_config --description="Change the kubectl config file"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch config"
	argparse -n "$_KS_SELF" -x 'help,current,list,complete-suggestions' \
		'h/help' 'c/current' 'L/list' 'complete-suggestions' \
		-- $argv || return 1

	# Handle the --complete-suggestions flag.
	if [ -n "$_flag_complete_suggestions" ]
		__kubeswitch_suggest_kubeconfig
		return $status
	end
		
	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		__kubeswitch_help_kubeswitch_config
		return 0
	end

	# Handle the --current flag.
	if [ -n "$_flag_current" ]
		__kubeswitch_current_kubeconfig
		return $status
	end

	# Handle the --list flag.
	if [ -n "$_flag_list" ] 
		__kubeswitch_list_kubeconfig
		return $status
	end

	if [ (count $argv) -eq 1 ]
		set -l file (__kubeswitch_resolve_kubeconfig "$argv[1]") || return $status
		__kubeswitch_change_kubeconfig "$file" || return $status
		__kubeswitch_util_message "Changed kubeconfig to %s." "$argv[1]"
		return 0
	else if [ (count $argv) -gt 1 ]
		printf "%s: %s\n" \
			"$_KS_SELF" "only one kubeconfig file may be active" 1>&2
		return 1
	end

	# Handle interactive
	__kubeswitch_do_interactive \
		--list="__kubeswitch_list_kubeconfig --absolute" \
		--list-map="__kubeswitch_util_filename" \
		--selected=(__kubeswitch_current_kubeconfig) \
		--callback="__kubeswitch_subcmd_config"
end

function __kubeswitch_subcmd_context --description="Change the kubectl config context"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch context"
	argparse -n "$_KS_SELF" -x 'help,current,list,complete-suggestions' \
		'h/help' 'c/current' 'L/list' 'complete-suggestions' \
		-- $argv || return 1
	
	# Handle the --complete-suggestions flag.
	if [ -n "$_flag_complete_suggestions" ]
		__kubeswitch_suggest_context
		return $status
	end
		
	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		__kubeswitch_help_kubeswitch_context
		return 0
	end

	# Handle the --current flag.
	if [ -n "$_flag_current" ]
		__kubeswitch_current_context
		return $status
	end

	# Handle the --list flag.
	if [ -n "$_flag_list" ]
		__kubeswitch_list_context
		return $status
	end

	if [ (count $argv) -eq 1 ]
		__kubeswitch_change_context "$argv[1]" || return $status
		__kubeswitch_util_message "Changed kubeconfig context to %s." "$argv[1]"
		return 0
	else if [ (count $argv) -gt 1 ]
		printf "%s: %s\n" \
			"$_KS_SELF" "only one kubeconfig context may be active" 1>&2
		return 1
	end

	# Handle interactive
	__kubeswitch_do_interactive \
		--list="__kubeswitch_list_context" \
		--selected=(__kubeswitch_current_context) \
		--callback="__kubeswitch_subcmd_context"
end

function __kubeswitch_subcmd_namespace --description="Change the kubectl namespace"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch namespace"
	argparse -n "$_KS_SELF" -x 'help,current,list,complete-suggestions' \
		'h/help' 'c/current' 'L/list' 'complete-suggestions' \
		-- $argv || return 1
	
	# Handle the --complete-suggestions flag.
	if [ -n "$_flag_complete_suggestions" ]
		__kubeswitch_list_namespace
		return $status
	end

	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		__kubeswitch_help_kubeswitch_namespace
		return 0
	end

	# Handle the --current flag.
	if [ -n "$_flag_current" ]
		__kubeswitch_current_namespace
		return $status
	end

	# Handle the --list flag.
	if [ -n "$_flag_list" ]
		__kubeswitch_list_namespace
		return $status
	end

	if [ (count $argv) -eq 1 ]
		__kubeswitch_change_namespace "$argv[1]" || return $status
		__kubeswitch_util_message "Changed kubernetes namespace to %s." "$argv[1]"
		return 0
	else if [ (count $argv) -gt 1 ]
		printf "%s: %s\n" \
			"$_KS_SELF" "only one kubeconfig namespace may be selected" 1>&2
		return 1
	end

	# Handle interactive
	__kubeswitch_do_interactive \
		--list="__kubeswitch_list_namespace" \
		--selected=(__kubeswitch_current_namespace) \
		--callback="__kubeswitch_subcmd_namespace"
end

function __kubeswitch_subcmd_kubectl --description="Run kubectl within the kubeswitch context"
	set -l kube_args

	set -l file      (__kubeswitch_current_kubeconfig)
	set -l context   (__kubeswitch_current_context)
	set -l namespace (__kubeswitch_current_namespace)

	# Override context/namespace.
	set -l user_args
	set -l user_passthrough_args
	set -l i 1
	while [ $i -le (count $argv) ]
		set -l arg "$argv[$i]"
		set i (math $i + 1)

		if [ "$arg" = "--" ]
			set user_passthrough_args "--" $argv[$i..]
			break
		end

		set -l argname
		set -l argvalue
		if string match -q --regex -- '^--(?<argname>[^=]+)(?:=(?<argvalue>.*))?$' "$arg"
			set -l prev_i "$i"
			if [ -z "$argvalue" ]
				set argvalue "$argv[$i]"
				set i (math $i + 1)
			end

			if [ -n "$argvalue" ]
				switch "$argname"
					case "context"
						set context "$argvalue"
						continue
					case "namespace"
						set namespace "$argvalue"
						continue
				end
			end

			# Restore the argument value if we didn't consume it.
			set i "$prev_i"
		end

		# An argument to pass along.
		set -a user_args "$arg"
		continue
	end

	# Append arguments.
	if [ -n "$context" ]
		set -a kube_args --context="$context"
	end

	if [ -n "$namespace" ]
		set -a kube_args --namespace="$namespace"
	end

	# Check if the kubectl plugin is blacklisted.
	set -l blacklist "krew" $kubeswitch_unsupported_plugins
	if test (count $argv) -gt 0 && contains -- "$argv[1]" $blacklist
		set kube_args
	end

	# If autocompleting, move the to-be-completed word to the end.
	if test (count $argv) -gt 1 && test "$argv[1]" = "__complete"
		set -a user_passthrough_args $user_args[(count $user_args)]
		set -e user_args[(count $user_args)]
	end

	# Run kubectl.
	if [ -n "$file" ]
		KUBECONFIG="$file" __kubeswitch_real_kubectl $user_args $kube_args $user_passthrough_args
		return $status
	else
		__kubeswitch_real_kubectl $user_args $kube_args $user_passthrough_args
		return $status
	end
end

function __kubeswitch_subcmd_kubectl_alias --description="Create an alias for kubectl"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch kubectl-alias"
	argparse -n "$_KS_SELF" 'help' -- $argv || return 1

	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		__kubeswitch_help_kubeswitch_kubectl_alias
		return 0
	end

	# Validate an alias is provided.
	set -l alias "$argv[1]"
	if [ -z "$alias" ]
		echo "$_KS_SELF: an alias name must be provided" 1>&2
		return 1
	end

	# Create the alias
	function "$alias" --wraps="kubectl"
		# Alias created by 'kubeswitch kubectl-alias'
		kubeswitch kubectl $argv
		return $status
	end

	return 0
end

function __kubeswitch_subcmd_inherit_env --description="Inherit kubeswitch environment"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch inherit-env"
	argparse -n "$_KS_SELF" 'help' -- $argv || return 1

	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		__kubeswitch_help_kubeswitch_inherit_env
		return 0
	end

	# Abort if safe mode is enabled.
	if [ "$__kubeswitch_safe_mode" = "true" ]
		return 20
	end

	# Copy the __kubeswitch_last_* variables.
	if [ -n "$__kubeswitch_last_kubeconfig$__kubeswitch_last_context$__kubeswitch_last_namespace" ]
		set -gx KUBECONFIG "$__kubeswitch_last_kubeconfig"
		set -gx KUBESWITCH_CONTEXT "$__kubeswitch_last_context"
		set -gx KUBESWITCH_NAMESPACE "$__kubeswitch_last_namespace"
	end

	return 0
end

function __kubeswitch_subcmd_show --description="Inherit kubeswitch environment"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch show"
	argparse -n "$_KS_SELF" -x 'help,porcelain,ksi' \
		'help' 'porcelain' 'ksi' -- $argv || return 1

	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		__kubeswitch_help_kubeswitch_show
		return 0
	end

	# Handle the --porcelain flag.
	set -g _KS_PORCELAIN false
	[ -n "$_flag_porcelain" ] && set _KS_PORCELAIN true

	# Print variables about the kubeswitch environment.
	set -l kube_config    (__kubeswitch_current_kubeconfig)
	set -l kube_context   (__kubeswitch_current_context)
	set -l kube_namespace (__kubeswitch_current_namespace)
	
	if [ -z "$_flag_ksi" ]

		__kubeswitch_util_show "$kube_config" \
			--var="CONFIG_FILE" --description="kubeconfig file"
		
		__kubeswitch_util_show (__kubeswitch_util_filename "$kube_config") \
			--var="CONFIG_NAME" --description="kubeconfig file name" \
			--porcelain-only

		__kubeswitch_util_show "$kube_context" \
			--var="ACTIVE_CONTEXT" --description="kubectl context"

		__kubeswitch_util_show $KUBESWITCH_CONTEXT \
			--var="DECLARED_CONTEXT" --description="kubeswitch context" \
			--porcelain-only
		
		__kubeswitch_util_show (__kubeswitch_list_context) \
			--var="AVAILABLE_CONTEXTS" --description="kubeswitch context" \
			--porcelain-only
		
		__kubeswitch_util_show "$kube_namespace" \
			--var="ACTIVE_NAMESPACE" --description="kubectl namespace"

		__kubeswitch_util_show $KUBESWITCH_NAMESPACE \
			--var="DECLARED_NAMESPACE" --description="kubeswitch namespace" \
			--porcelain-only
	
	end
	
	# Get the yq command for extracting user-supplied info from a .ksi file.
	set -l ksi_yq (
		__kubeswitch_ksi_extract --print-command \
			--context="$kube_context" \
			--namespace="$kube_namespace" \
			--config-file="$kube_config"
	)

	# Run the yq command.
	if [ (count $ksi_yq) -gt 0 ]
		if [ "$_KS_PORCELAIN" = true ]
			__kubeswitch_util_show ($ksi_yq | string collect --no-trim-newlines) \
				--var="KSI_YAML"
		else
			if [ -z "$_flag_ksi" ]
				echo "--- user-defined information ---"
			end

			if [ "$_KS_COLOR" = true ]
				set ksi_yq $ksi_yq[1] '--colors' $ksi_yq[2..-1]
			else
				set ksi_yq $ksi_yq[1] '--no-colors' $ksi_yq[2..-1]
			end

			$ksi_yq
			if [ $status -ne 0 ] && [ -n "$_flag_ksi" ]
				return 1
			end
		end
	end

	# Cleanup.
	set -g -e _KS_PORCELAIN
	return 0
end

function __kubeswitch_subcommand_wrapper_bin --description="Generate a shell script that wraps the kubectl binary"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "kubeswitch wrapper-bin"
	argparse -n "$_KS_SELF" 'help' -- $argv || return 1

	# Handle the --help flag.
	if [ -n "$_flag_help" ]
		__kubeswitch_help_kubeswitch_wrapper_bin
		return 0
	end

	# If attached to a terminal, write it to a file.
	if test -t 1
		mkdir -p "$HOME/.local/bin"
		__kubeswitch_subcommand_wrapper_bin >"$HOME/.local/bin/kubectl"
		chmod +x "$HOME/.local/bin/kubectl"
		return 0
	end

	# Print the shell script.
	printf "%s\n" \
		"#!/usr/bin/env bash" \
		"# --------------- Generated by fish-kubeswitch ---------------" \
		"# Repo: https://github.com/eth-p/fish-kubeswitch" \
		"# File: "(status filename) \
		"# ------------------------------------------------------------" \
		"# Find the real kubectl." \
		'while read -r -d":" dir; do' \
		'    kubectl="$dir/kubectl"' \
		'    if [[ -x "$kubectl" && "${BASH_SOURCE[0]}" != "$kubectl" ]]; then' \
		'        break' \
		'    fi' \
		'done <<< "$PATH:"' \
		'' \
		'# Run kubectl through kubeswitch.' \
		'fish -c "set -g __kubeswitch_safe_mode true; set -g kubeswitch_kubectl \$argv[1]; kubeswitch kubectl \$argv[2..]" "$kubectl" "$@"' \
		'exit $?'
	return 0
end

# -----------------------------------------------------------------------------
# Helpers: Utilities
# -----------------------------------------------------------------------------

# __kubeswitch_util_basename is a pure fish reimplementation of the `basename`
# command. This avoids the overhead of forking the actual command.
function __kubeswitch_util_basename --description="Extract the file basename from a path"
	if [ -z "$argv[1]" ]
		echo ""
		return 0
	end

	# Clean up the path and extract the segments.
	set -l segments (
		string replace --regex --all -- '/{2,}' '/' "$argv[1]" \
			| string replace --regex --all -- '/+$' '' \
			| string split '/'
	)

	# Extract the rightmost segment.
	set -l basename "$segments[-1]"
	if [ -z "$basename" ]
		set basename "/"
	end

	# If the 2nd argument is not empty, trim the suffix.
	if [ -n "$argv[2]" ]
		set -l suffix_length (string length -- "$argv[2]")
		if [ (string sub --start="-$suffix_length" -- "$basename") = "$argv[2]" ]
			set basename (string sub --end="-$suffix_length" -- "$basename")
		end
	end

	# Print the basename.
	echo "$basename"
end

function __kubeswitch_util_extname --description="Extract the file extension from a path"
	__kubeswitch_util_basename "$argv[1]" \
		| string replace --regex -- '^(.+)(\..*)$' '$2' \
		| string match '.*'
end

function __kubeswitch_util_filename --description="Extract the file name from a path"
	__kubeswitch_util_basename "$argv[1]" \
		(__kubeswitch_util_extname "$argv[1]")
end

function __kubeswitch_util_color --description="Print the first available color"
	if [ "$_KS_COLOR" != true ]
		return 0
	end

	# Collect possible variables.
	set -l var
	set -l vars
	set -l fallback
	set -l to_fallback false
	for var in $argv
		if "$to_fallback"
			set -a fallback $var
			continue
		end

		if [ "$var" = "--" ]
			set to_fallback true
			continue
		end

		set -a vars $var
	end

	# Try all the listed variables.
	for var in $vars
		eval "set -l color \$$var"
		if [ (count $color) -ne 0 ]
			set_color $color
			return $status
		end
	end

	# Use the fallback
	if [ (count $fallback) -gt 0 ]
		set_color $fallback
		return $status
	end

	# No color.
	return 1
end

function __kubeswitch_util_message --description="Prints a message"
	if [ "$_KS_QUIET" = "true" ]
		return 0
	end

	# Get the color codes.
	set -l active_color_code (__kubeswitch_util_color kubeswitch_color_message -- green)
	set -l reset_color_code (__kubeswitch_util_color -- normal)

	# Print the message.
	printf "%s%s%s\n" "$active_color_code" (printf $argv) "$reset_color_code"
	return 0
end

function __kubeswitch_util_show --description="Prints info about a kubeswitch environment variable"
	argparse 'var=' 'description=' 'porcelain-only' -- $argv || return 1

	# If porcelain mode, print it in a fish-eval'able format.
	if [ "$_KS_PORCELAIN" = "true" ]
		printf "set -l %s" $_flag_var
		if [ (count $argv) -gt 0 ]
			printf ' %s' (string escape $argv)
		end
		printf ";\n"
		return 0
	end

	# If it's only meant to be printed in porcelain mode, don't print it.
	if [ -n "$_flag_porcelain_only" ]
		return 0
	end

	# Print it.
	set -l active_color_code (__kubeswitch_util_color kubeswitch_color_show_var -- cyan)
	set -l reset_color_code (__kubeswitch_util_color -- normal)
	printf "%s%-20s%s %s\n" \
		"$active_color_code" \
		"$_flag_description:" \
		"$reset_color_code" \
		"$argv"
end



# -----------------------------------------------------------------------------
# Helpers: Interactive Selection
# -----------------------------------------------------------------------------

# Interatively pick an option and run the command specified in `--callback`.
#
# Options:
#
#   --list       :: A command which generates a list of options.
#   --list-map   :: A command which maps an option to a simplified name.
#   --selected   :: The option that is currently selected.
#   --callback   :: The function to run when a user selects an option.
#
function __kubeswitch_do_interactive --description="Use fzf to pick an option"
	argparse 'list=' 'list-map=' 'selected=' 'callback=' -- $argv || return 1

	# Make sure --list is provided.
	if [ -z "$_flag_list" ]
		echo "__kubeswitch_do_interactive: requires --list" 1>&2
		return 1
	end
	
	# Get the list of items.
	set -l list_items (eval "$_flag_list")
	set -l list_names
	if [ -n "$_flag_list_map" ]
		set -l item
		for item in $list_items
			set -a list_names (eval "$_flag_list_map" "$item")
		end
	else
		set list_names $list_items
	end

	# Find the selected item.
	set -l selected_item
	if [ -n "$_flag_selected" ]
		set selected_item (contains --index -- "$_flag_selected" $list_items)
	end

	# Interactively pick an item and run the callback.
	if [ "$kubeswitch_enable_fzf" != "false" ] && command -vq fzf
		# TODO: Interactive
	end
	
	# No fzf or disabled? Just list the options.
	set -l active_color_code (__kubeswitch_util_color kubeswitch_color_active fish_color_search_match)
	set -l reset_color_code (__kubeswitch_util_color -- normal)

	if [ (count $list_items) -eq 0 ]
		echo "[nothing available]" 1>&2
		return 0
	end
	
	set -l i
	for i in (seq 1 (count $list_items))
		set -l item_value $list_items[$i]
		set -l item_name $list_names[$i]

		if [ "$i" = "$selected_item" ]
			printf "%s%s%s\n" "$active_color_code" "$item_name" "$reset_color_code"
		else
			printf "%s\n" "$item_name"
		end
	end

	return 2
end



# -----------------------------------------------------------------------------
# Helpers: Kubectl File
# -----------------------------------------------------------------------------

function __kubeswitch_current_kubeconfig --description="Get the current kubectl config file"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_current_kubeconfig"
	argparse -n "$_KS_SELF" 'x-no-options' -- $argv || return 1

	if [ -n "$KUBECONFIG" ]
		echo "$KUBECONFIG"
	else
		echo "$HOME/.kube/config"
	end
end

# Options:
#
#   --absolute          :: Changes the default context of the kubeconfig file.
#   --abort-on-warning  :: Aborts if a warning is encountered.
#
function __kubeswitch_list_kubeconfig --description="List all kubectl config files"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_list_kubeconfig"
	argparse -n "$_KS_SELF" 'absolute' 'abort-on-warning' -- $argv || return 1
	
	# Make sure a default search path is set.
	set -l kubeswitch_kubeconfig_path $kubeswitch_kubeconfig_path
	if [ (count $kubeswitch_kubeconfig_path) -eq 0 ]
		set kubeswitch_kubeconfig_path "$HOME/.kube/configs"
	end
	
	# Make sure default search extensions are set.
	set -l kubeswitch_kubeconfig_exts $kubeswitch_kubeconfig_exts
	if [ (count $kubeswitch_kubeconfig_exts) -eq 0 ]
		set kubeswitch_kubeconfig_exts '' '.yaml' '.yml'
	end

	# Search
	set -l configs
	set -l dir
	set -l file
	set -l seen_file_names
	set -l seen_files
	for dir in $kubeswitch_kubeconfig_path
		for file in "$dir"/*
			# Make sure file extension matches the allowed extensions.
			set -l file_ext (__kubeswitch_util_extname "$file")
			if ! contains -- "$file_ext" $kubeswitch_kubeconfig_exts
				continue
			end

			# Add the file to the list of seen files.
			set -l file_name (__kubeswitch_util_basename "$file" "$file_ext")
			set -l file_seen_at (contains --index -- "$file_name" $seen_file_names)

			if [ -n "$file_seen_at" ]
				printf "warning: kubeconfig file '%s' is shadowed by '%s'\n" \
					"$file" "$seen_files[$file_seen_at]" 1>&2

				if [ -n "$_flag_abort_on_warning" ]
					return 1
				else
					continue
				end
			end

			set -a seen_file_names "$file_name"
			set -a seen_files "$file"

			# Print the file.
			if [ -n "$_flag_absolute" ]
				echo "$file"
			else
				echo "$file_name"
			end
		end
	end

	return 0
end

function __kubeswitch_change_kubeconfig --description="Change the current kubectl config file"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_change_kubeconfig"
	argparse -n "$_KS_SELF" 'x-no-options' -- $argv || return 1

	set -l kubefile "$argv[1]"

	# Validate the provided kubeconfig file path is a file.
	if [ -z "$kubefile" ]
		echo "$_KS_SELF: an argument must be provided" 1>&2
		return 1
	end

	if ! [ -e "$kubefile" ]
		echo "$_KS_SELF: kubeconfig file '$kubefile' does not exist" 1>&2
		return 1
	end

	if ! [ -f "$kubefile" ]
		echo "$_KS_SELF: kubeconfig file '$kubfile' is not a file" 1>&2
		return 1
	end

	# Abort if safe mode is enabled.
	if [ "$__kubeswitch_safe_mode" = "true" ]
		echo "$_: cannot change kubeconfig file from kubectl wrapper binary" 1>&2
		return 20
	end

	# Set KUBECONFIG to the absolute path of the kubeconfig file.
	set -l kubefile_absolute (realpath -- "$kubefile")
	set -gx KUBECONFIG "$kubefile"

	# Unset the context and namespace when the kubeconfig changes.
	set -ge KUBESWITCH_CONTEXT
	set -ge KUBESWITCH_NAMESPACE

	# Emit the "kubeswitch" event to let other scripts know that the
	# kubernetes config file has changed.
	emit kubeswitch file "$kubefile"
	return 0
end

function __kubeswitch_suggest_kubeconfig --description="Suggest a kubeconfig file"
	set -l file
	for file in (__kubeswitch_list_kubeconfig --absolute 2>/dev/null)
		# Use kubectl to extract the cluster name.
		set -l cluster (
			KUBECONFIG="$file" command \
			kubectl config view --minify --output='jsonpath={..clusters[0].name}' 2>/dev/null
		)

		# Print the config file name and cluster name.
		printf "%s\t%s\n" \
			(__kubeswitch_util_filename "$file") \
			"$cluster"
	end
end

# Resolves the full path of a kubecfg file named in the
# `$kubeswitch_kubeconfig_path` search path. If a relative or absolute file
# path is provided and `--only-path` is not set, it will try to use that
# file path instead.
#
# Options:
#
#   --only-path    :: Only use the search path.
#
function __kubeswitch_resolve_kubeconfig --description="Resolve a kubeconfig file"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_resolve_kubeconfig"
	argparse -n "$_KS_SELF" 'only-path' -- $argv || return 1

	# Validate the provided kubeconfig file name is provided.
	set -l kubefile "$argv[1]"
	if [ -z "$kubefile" ]
		echo "$_KS_SELF: an argument must be provided" 1>&2
		return 1
	end

	# Resolve relative files.
	if [ -z "$_flag_only_path" ]
		switch "$kubefile"
		case "./*" "../*" "/*"
			if ! [ -f "$kubefile" ]
				echo "$_KS_SELF: kubeconfig file '$kubefile' does not exist" 1>&2
				return 1
			end

			realpath -- "$kubefile"
			return 0
		end
	end

	# Resolve search path files.
	set -l files (__kubeswitch_list_kubeconfig --absolute)
	set -l file
	for file in $files
		if [ (__kubeswitch_util_filename "$file") = "$kubefile" ]
			echo "$file"
			return 0
		end
	end

	# Couldn't find it.	
	echo "$_KS_SELF: kubeconfig file '$kubefile' does not exist" 1>&2
	return 1
end



# -----------------------------------------------------------------------------
# Helpers: Kubectl Context
# -----------------------------------------------------------------------------

function __kubeswitch_current_context --description="Get the current kubectl context"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_current_context"
	argparse -n "$_KS_SELF" 'x-no-options' -- $argv || return 1

	if [ -n "$KUBESWITCH_CONTEXT" ]
		echo "$KUBESWITCH_CONTEXT"
	else
		__kubeswitch_real_kubectl config current-context 2>/dev/null || return $status
	end
end

function __kubeswitch_list_context --description="List all kubectl contexts"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_list_context"
	argparse -n "$_KS_SELF" 'x-no-options' -- $argv || return 1

	__kubeswitch_real_kubectl config get-contexts --output="name" || return 1
end

# Options:
#
#   --universal  :: Changes the default context of the kubeconfig file.
#
function __kubeswitch_change_context --description="Change the current kubectl context"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_change_context"
	argparse -n "$_KS_SELF" 'U/universal' -- $argv || return 1

	# Validate the provided context exists.
	set -l context "$argv[1]"
	if [ -z "$context" ]
		echo "$_: an argument must be provided" 1>&2
		return 1
	end

	if ! contains -- "$context" (__kubeswitch_list_context)
		echo "$_: kubeconfig context '$context' does not exist" 1>&2
		return 1
	end

	# Abort if safe mode is enabled.
	echo "HI"
	if [ "$__kubeswitch_safe_mode" = "true" ]
		echo "$_: cannot change context from kubectl wrapper binary" 1>&2
		return 20
	end

	# Change the context.
	if [ -n "$_flag_universal" ]
		__kubeswitch_real_kubectl config use-context -- "$context" \
			>/dev/null || return $status
	else
		set -gx KUBESWITCH_CONTEXT "$context"
	end

	# Unset the namespace when the context changes.
	set -ge KUBESWITCH_NAMESPACE

	# Emit the "kubeswitch" event to let other scripts know that the
	# kubernetes context has changed.
	emit kubeswitch context "$context" $_flag_universal
	return 0
end

function __kubeswitch_suggest_context --description="Suggest a kubeconfig context"
	set -l context
	for context in (__kubeswitch_list_context 2>/dev/null)
		# Use kubectl to extract the cluster name and namespace.
		set -l cluster_and_namespace (
			__kubeswitch_real_kubectl --context="$context" \
				config view --minify \
				--output='jsonpath={..clusters[0].name}/{..namespace}'
		) 2>/dev/null

		# Append "default" if missing.
		switch "$cluster_and_namespace"
		case "*/"
			set cluster_and_namespace "$cluster_and_namespace""default"
		end

		# Print the context name and cluster name + namespace.
		printf "%s\t%s\n" \
			"$context" \
			"$cluster_and_namespace"
	end
end



# -----------------------------------------------------------------------------
# Helpers: Kubectl Namespace
# -----------------------------------------------------------------------------

function __kubeswitch_current_namespace --description="Get the current kubectl namespace"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_current_namespace"
	argparse -n "$_KS_SELF" 'x-no-options' -- $argv || return 1

	if [ -n "$KUBESWITCH_NAMESPACE" ]
		echo "$KUBESWITCH_NAMESPACE"
	else
		set -l namespace (__kubeswitch_real_kubectl config view --minify --output='jsonpath={..namespace}' 2>/dev/null)
		if [ -z "$namespace" ]
			echo "default"
		end
	end
end

function __kubeswitch_list_namespace --description="List all kubectl namespaces"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_list_namespace"
	argparse -n "$_KS_SELF" 'x-no-options' -- $argv || return 1

	string replace --regex -- \
		'^namespace/' '' \
		(__kubeswitch_real_kubectl get namespace --output='name' 2>/dev/null) \
		|| return 1
end

# Options:
#
#   --validate   :: Validate that the namespace exists (slow).
#   --universal  :: Changes the namespace of the kubeconfig file's current context.
#
function __kubeswitch_change_namespace --description="Change the current kubectl namepsace"
	[ -n "$_KS_SELF" ] || set -l _KS_SELF "__kubeswitch_change_namespace"
	argparse -n "$_KS_SELF" 'U/universal' 'V/validate' -- $argv || return 1

	# Validate the provided namespace exists.
	set -l namespace "$argv[1]"
	if [ -z "$namespace" ]
		echo "$_: an argument must be provided" 1>&2
		return 1
	end

	if [ -n "$_flag_validate" ]
		if ! contains -- "$namespace" (__kubeswitch_list_namespace)
			echo "$_: namespace '$namespace' does not exist" 1>&2
			return 1
		end
	end

	# Abort if safe mode is enabled.
	if [ "$__kubeswitch_safe_mode" = "true" ]
		echo "$_: cannot change namespace from kubectl wrapper binary" 1>&2
		return 20
	end

	# Change the context.
	if [ -n "$_flag_universal" ]
		__kubeswitch_real_kubectl config set-context --current --namespace="$namespace" \
			>/dev/null || return $status
	else
		set -gx KUBESWITCH_NAMESPACE "$namespace"
	end

	# Emit the "kubeswitch" event to let other scripts know that the
	# kubernetes context has changed.
	emit kubeswitch namespace "$namespace" $_flag_universal
	return 0
end



# -----------------------------------------------------------------------------
# Helpers: Kubectl KSI
# -----------------------------------------------------------------------------

function __kubeswitch_ksi_file --description="Get the .ksi file for the current config"
	argparse 'config-file=' -- $argv || return 1
	
	[ -n "$_flag_config_file" ] || set _flag_config_file (__kubeswitch_current_kubeconfig)
	
	printf "%s/%s.%s\n" \
		(dirname -- "$_flag_config_file") \
		(__kubeswitch_util_filename "$_flag_config_file") \
		"ksi"
end

function __kubeswitch_ksi_extract --description="Extract the active fields from a .ksi file"
	argparse 'config-file=' 'config-name=' 'context=' 'namespace=' 'print-command' \
		-- $argv || return 1

	# Ensure yq is installed.
	if ! command -vq yq
		return 2
	end

	# Find the .ksi file to read from.
	set -l files

	set -l specific_file (__kubeswitch_ksi_file --config-file="$_flag_config_file")
	set -l general_file (dirname -- "$specific_file")/"_common.ksi"
	for file in $general_file $specific_file
		if [ -f "$file" ]
			set -a files "$file"
		end
	end

	if [ (count $files) -lt 1 ]
		return 1
	end

	# Get the list of keys.
	set -l keys (
		yq eval-all '. as $item ireduce ({}; . *+ $item ) | keys' $files \
		| string match -- '- *' \
		| string replace --regex '^- "(.*)"' '$1'
	) || return 1

	# Get default options.
	[ -n "$_flag_context" ] || set _flag_context (__kubeswitch_current_context)
	[ -n "$_flag_namespace" ] || set _flag_namespace (__kubeswitch_current_namespace)
	[ -n "$_flag_config_name" ] || set _flag_config_name \
		(__kubeswitch_util_filename (__kubeswitch_current_kubeconfig))

	# Match the keys against the environment.
	set -l matching_indices
	set -l key
	set -l index 0
	for key in $keys
		set -l match_string "$_flag_namespace@$_flag_context"
		set -l match_query "$key"

		switch "$key"
		case "[file=]*"
			set match_string "$_flag_config_name"
			set match_query (string sub --start=8 -- "$key")
		case "[namespace=]*"
			set match_string "$_flag_namespace"
			set match_query (string sub --start=13 -- "$key")
		case "[context=]*"
			set match_string "$_flag_context"
			set match_query (string sub --start=11 -- "$key")
		end

		if string match -q -- "$match_query" "$match_string"
			set -a matching_indices "$index"
		end

		set index (math $index + 1)
	end

	# Generate a yq command for extracting from the matching keys.
	set -l yq_query (
		string replace --all --regex -- '([\\\\"])' '\\\\$1' $matching_indices |
		string replace --regex -- '^(.*)$' '.[$1].value' |
		string join -- ' * '
	)

	# If the query is empty, return without calling yq.
	if [ -z "$yq_query" ]
		return 0
	end

	set -l yq_command 'yq' 'eval-all' '--' ". as \$item ireduce ({}; . *+ \$item ) | to_entries | $yq_query" $files
	for key in $matching_keys
		set -a yq_query "$key"
	end

	# Run yq.
	if [ -n "$_flag_print_command" ]
		printf "%s\n" $yq_command
		return 0
	end

	$yq_command
	return $status
end


# -----------------------------------------------------------------------------
# Helpers: Kubectl Command
# -----------------------------------------------------------------------------

function __kubeswitch_real_kubectl --description="Runs the real kubectl command"
	if [ -n "$kubeswitch_kubectl" ]
		command $kubeswitch_kubectl $argv
		return $status
	else if [ -n "$__kubeswitch_real_kubectl_command" ]
		command "$__kubeswitch_real_kubectl_command" $argv
		return $status
	end

	# Find the real kubectl command.
	set -l kubectls (command -a kubectl)
	if head -c 4096 "$kubectls[1]" | grep -F -- "Generated by fish-kubeswitch" &>/dev/null
		set -e kubectls[1]
	end

	set -g __kubeswitch_real_kubectl_command "$kubectls[1]"
	command "$__kubeswitch_real_kubectl_command" $argv
	return $status
end

set -e __kubeswitch_real_kubectl_command
