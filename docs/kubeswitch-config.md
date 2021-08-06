# kubeswitch config

View or change the kubectl config file used by `kubeswitch kubectl`.

<u>Aliases</u>: `cfg`, `kubeconfig`, `kubefile`, `kubecfg`



## Usage

| Command                       | Description                          |
| ----------------------------- | ------------------------------------ |
| `kubeswitch config`           | List/change config files.            |
| `kubeswitch config <NAME>`    | Switch to the specified config file. |
| `kubeswitch config --list`    | List the available config files.     |
| `kubeswitch config --current` | Show the current config file.        |



## Search Path

When changing the config file, `kubeswitch config` will look for config files in the search path declared by the `$kubeswitch_kubeconfig_path` variable. This works similarly to fish's `$PATH` variable, but with an additional requirement that requires the files have one of the extensions within the `$kubeswitch_kubeconfig_exts` variables.

Example:

```console
$ set -g kubeswitch_kubeconfig_path ~/.kube/configs ~/.kubeconfigs
$ set -g kubeswitch_kubeconfig_exts '' '.yaml'

$ ls ~/.kube/configs
some.file my-cluster.yaml

$ ls ~/.kubeconfigs
my-other-cluster.yaml

$ kubeswitch config --list
my-cluster
my-other-cluster
```

If you want to select a specific config file, you can use a relative (starting with `./`) path or absolute path to the config file.
