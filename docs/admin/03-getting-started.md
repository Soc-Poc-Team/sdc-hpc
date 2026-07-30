# Getting Started

This chapter guides you through the steps required to prepare for the deployment
of your own `small-data-cluster`.

Before proceeding, we strongly recommend reading the previous chapter in full.
In particular, administrators planning to deploy a `small-data-cluster` in a
professional or production environment should carefully review the provided
security information and assess the associated risks.

Unfortunately, we cannot provide universal support for every hardware
configuration, network environment, or deployment scenario. Some troubleshooting
and adaptation may therefore be required. The software tries its best to work in
any environment it is deployed in.

## Assumptions

The following instructions assume that you have:

- A Nix-enabled Linux or NixOS machine
- A working internet connection
- An account with `sudo` privileges

All subsequent steps are based on these assumptions.

## Enable Experimental Nix Features

Nix is a package manager, a configuration language, and the foundation of the
NixOS operating system. Some commonly used Nix features are still classified as
experimental and must be explicitly enabled before they can be used.
Experimental features are not considered stable and may change incompatibly or
be removed in future versions of Nix - for our "experimental features" this is
highly unlikely as they are the de-facto standard when it comes to working with
nix today.

The `small-data-cluster` relies on the following experimental features:

- `nix-command` enables the modern `nix` command-line interface and subcommands
  such as `nix build`, `nix develop`, and `nix flake`.
- `flakes` enables the flake project format. A flake uses a `flake.nix` file to
  declare its inputs and outputs and usually a `flake.lock` file to record
  specific dependency versions. The `small-data-cluster` repository does this.

We will enable both features globally so that they do not need to be specified
separately for every command.

> **Note:** Enabling experimental Nix features affects all users and Nix
> commands on the machine. On shared systems, ensure that this configuration
> change is acceptable to the system administrator.

### On NixOS

NixOS systems are managed declaratively through a configuration written in the
Nix language. Instead of changing most system settings manually, administrators
describe the desired system configuration in one or more `.nix` files. The
primary configuration file is normally located at
`/etc/nixos/configuration.nix`, although it may import additional configuration
files. Changes are applied by rebuilding the system configuration. See the
[Changing the Configuration](https://nixos.org/manual/nixos/stable/#sec-changing-config)
section of the NixOS manual for further information.

Add the following setting to your NixOS configuration, usually in
`/etc/nixos/configuration.nix`. Editing this file requires root privileges:

```nix
nix.settings.experimental-features = [ "nix-command" "flakes" ];
```

Apply the updated configuration:

```bash
sudo nixos-rebuild switch
```

The setting becomes part of the system configuration and remains enabled after
future rebuilds and restarts.

### On Nix-enabled Linux

On other Linux distributions, Nix is configured through a file named `nix.conf`.
The system-wide configuration file is normally located at `/etc/nix/nix.conf`.
See the
[`nix.conf` reference documentation](https://nix.dev/manual/nix/stable/command-ref/conf-file.html)
for further information.

Create or edit `/etc/nix/nix.conf` with root privileges and add the following
line:

```ini
experimental-features = nix-command flakes
```

When you do not have permission to modify the system-wide configuration, you may
instead add the same setting to:

```text
~/.config/nix/nix.conf
```

A configuration placed in this location applies only to the corresponding user
and does not enable the features globally for other users.

When using a multi-user Nix installation with the Nix daemon, restart the daemon
after changing the configuration. On Linux distributions using `systemd`, run:

```bash
sudo systemctl restart nix-daemon
```

## Optional: Install direnv

`direnv` is a shell extension that automatically loads and unloads
project-specific environment variables when you enter or leave a directory. It
uses an `.envrc` file stored in the project directory to define the environment
that should be activated.

Learn more about `direnv` on their official website
[direnv.net](https://direnv.net/).

The `small-data-cluster` repository uses `direnv` to provide convenient access
to its development environment and automatically make relevant tools and
settings available. `direnv` also configures tools for you and handles some part
of the secret management system. Without `direnv`, you may need to enter the
development environment manually whenever you start working with the repository
and you will not profit from automatic tool setup.

You can install `direnv` using your operating system’s package manager. On a
Nix-enabled system, you can install it for the current user with:

```bash
nix profile install nixpkgs#direnv
```

The `nix profile install` command adds the selected package to the user’s Nix
profile.

> Note: When you are a bit more fammilar with Nix, i personally strongly
> recommend not to use `nix profiles` and opt for more reproducable solutions
> like adding it to your system Packages via the configuration.

After installation, `direnv` must be connected to your shell using a shell hook.
Add the appropriate command for your shell to its configuration file.

### Bash

Add the following line to the end of `~/.bashrc`:

```bash
eval "$(direnv hook bash)"
```

Apply the change by restarting Bash or running:

```bash
source ~/.bashrc
```

### Fish

Fish is the default shell on the `small-data-cluster`. Add the following line to
`~/.config/fish/config.fish`:

```fish
direnv hook fish | source
```

Apply the change by restarting Fish or running:

```fish
source ~/.config/fish/config.fish
```

`direnv` requires explicit authorization before loading a new or modified
`.envrc` file. Because an `.envrc` file may contain executable shell commands,
inspect its contents before running `direnv allow`, particularly when working
with repositories obtained from an untrusted source.

Once authorized, the development environment will be loaded automatically
whenever you enter the repository directory and unloaded when you leave it.

We will come to this after cloning the repository.
