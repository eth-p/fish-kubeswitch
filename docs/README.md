# kubeswitch

The main `kubeswitch` command.



## Subcommands

[**kubeswitch config**](kubeswitch-config.md)  
View or change the kubectl config file used by `kubeswitch kubectl`.

[**kubeswitch context**](kubeswitch-context.md)  
View or change the active context used by `kubeswitch kubectl`.

[**kubeswitch namespace**](kubeswitch-namespace.md)  
View or change the active namespace used by `kubeswitch kubectl`.

[**kubeswitch kubectl**](kubeswitch-kubectl.md)  
Run `kubectl` in the `kubeswitch` environment.

[**kubeswitch kubectl-alias**](kubeswitch-kubectl-alias.md)  
Create an alias for `kubeswitch kubectl`.

[**kubeswitch inherit-env**](kubeswitch-inherit-env.md)  
Inherit the `kubeswitch` environment that was most recently set by another instance of fish.




## Usage

Kubeswitch acts a wrapper around the `kubectl` command, and only affects `kubectl` when run through `kubeswitch kubectl`. For convenience, you can use the [kubeswitch kubectl-alias](kubeswitch-kubectl-alias.md) subcommand to create an alias from `kubectl` to `kubeswitch kubectl`.

The `kubeswitch kubectl` (or the aliased `kubectl`) wrapper should be used in same way as the standard `kubectl` command.



### Changing the Config File

The [kubeswitch config](kubeswitch-config.md) subcommand can be used to change the active `kubectl` config file. This accepts a relative path (starting with `./` or `../`), or the name of a file within the `$kubeswitch_kubeconfig_path` search path.



### Changing the Active Context

The [kubeswitch context](kubeswitch-context.md) subcommand can be used to change the active context.



### Changing the Active Namespace

The [kubeswitch namespace](kubeswitch-namespace.md) subcommand can be used to change the active namespace.



## Configuration

`$kubeswitch_kubeconfig_path` (array)  
An array of directories that can contain `kubectl` configuration files.  
This is used as the search path for the `kubeswitch config` subcommand.

`$kubeswitch_kubeconfig_exts` (array)  
An array of valid extensions for `kubectl` configuration files.  
This is used to find files for `kubeswitch config` subcommand.

`$kubeswitch_color_active` (array)  
An array of `set_color` arguments used to highlight the active config file/context/namespace.

`$kubeswitch_color_message` (array)  
An array of `set_color` arguments used when printing a status message.

