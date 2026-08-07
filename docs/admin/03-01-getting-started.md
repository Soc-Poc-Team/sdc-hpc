# Getting started

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

## Enable experimental Nix features

Nix is a package manager, a configuration language, and the foundation of the
NixOS operating system. Some commonly used Nix features are still classified as
experimental and must be explicitly enabled before they can be used.
Experimental features are not considered stable and may change incompatibly or
be removed in future versions of Nix. However, these features are widely used
and are the de facto standard for working with modern Nix projects.

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

## Optional: install `direnv`

`direnv` is a shell extension that automatically loads and unloads
project-specific environment variables when you enter or leave a directory. It
uses an `.envrc` file stored in the project directory to define the environment
that should be activated.

Learn more about `direnv` on its official website,
[direnv.net](https://direnv.net/).

The `small-data-cluster` repository uses `direnv` to provide convenient access
to its development environment and automatically make relevant tools and
settings available. `direnv` also configures tools and handles part of the
secret-management system. Without `direnv`, you may need to enter the
development environment manually whenever you start working with the repository
and will not benefit from automatic tool setup.

You can install `direnv` using your operating system’s package manager. On a
Nix-enabled system, you can install it for the current user with:

```bash
nix profile install nixpkgs#direnv
```

The `nix profile install` command adds the selected package to the user’s Nix
profile.

> **Note:** For a reproducible setup, experienced Nix users may prefer to add
> `direnv` to their declarative system or home configuration instead of using
> `nix profile install`.

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

## Clone the repository

The `small-data-cluster` is distributed as a Git repository. Cloning the
repository downloads a local copy of the source code, documentation,
configuration files, and development tools to your build machine. You can then
configure the project and build the cluster’s ISO and virtual-machine images
locally.

Because the complete project source is available, you may also modify any part
of it to suit your specific requirements. Be aware that custom modifications may
affect compatibility with future updates and are not covered by the project’s
limited support.

A public mirror of the `small-data-cluster` repository is available at:

https://fhac.de/FB05/hpc-on-demand

You can clone the repository using either HTTPS or SSH. No credentials are
required to access the public repository. The following command clones the
`main` branch into `~/small-data-cluster`:

```bash
git clone https://git-ce.fh-aachen.de/bigdatalab/hpc-on-demand.git ~/small-data-cluster
```

Other branches may also be checked out, but only the `main` branch should be
considered the default supported version. No guarantee of stability,
compatibility, or completeness is provided for other branches.

Enter the cloned repository directory and authorize its `direnv` configuration:

```bash
cd ~/small-data-cluster
direnv allow
```

> **Note:** Before running `direnv allow`, ensure that `direnv` is installed and
> connected to your shell as described in
> [Optional: Install direnv](#optional-install-direnv). The command authorizes
> the repository’s `.envrc` file, which may execute shell commands on your build
> machine. Review the file before authorizing it when working with a modified or
> untrusted copy of the repository.

After authorization, Nix will download or build the dependencies required for
working with the project. The initial setup may take some time, depending on
your internet connection, hardware, and whether the required build results are
available from a binary cache.

The development environment will also initialize the project’s secret-management
tooling. It may attempt to decrypt configuration secrets for your user. This
attempt will most likely fail during the initial setup because your own secret
configuration has not yet been created and is not included in the public
repository. This is expected at this stage.

The `direnv` environment also creates or connects to a `tmux` session containing
windows for several common development and deployment tasks:

- `build-batch` provides commands for building ISO and virtual-machine images.
- `vms` provides commands for testing a virtualized headnode and worker node as
  QEMU virtual machines on the build machine.
- `flash` provides access to the flashing utility used to write
  `small-data-cluster` images to bootable USB drives.

> **Important:** Complete the following configuration steps before using the
> commands displayed in these `tmux` windows. Until the cluster configuration
> and required secrets have been created, the suggested build, virtualization,
> and flashing commands are not expected to work correctly. Do not run them yet.
