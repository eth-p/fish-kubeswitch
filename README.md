# fish-kubeswitch

A `kubectx`/`kubens` replacement that sets the `kubectl` config file, context, and namespace for each individual instance of the fish shell.



## Features

- Change the `kubectl` config file, context, and namespace of only one fish instance.
  (No more outdated/incorrect prompts!)
- Barebones installation, easy configuration.




## Install

With [fisher](https://github.com/jorgebucaran/fisher):

```fish
fisher install eth-p/fish-kubeswitch

# Make sure that "kubectl" runs within the kubeswitch environment.
echo "kubeswitch kubectl-alias kubectl" >> ~/.config/fish/config.fish

# New shell instances will use the last-set kubeswitch environment.
echo "kubeswitch inherit-env" >> ~/.config/fish/config.fish
```



## Documentation

[View the latest documentation in the docs folder.](docs/README.md)

