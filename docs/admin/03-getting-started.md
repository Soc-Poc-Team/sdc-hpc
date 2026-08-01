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

### Cloning the Repository

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

https://git-ce.fh-aachen.de/bigdatalab/hpc-on-demand

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
- `vms` provides commands for testing a virtualized headnode and workernode as
  QEMU virtual machines on the build machine.
- `flash` provides access to the flashing utility used to write
  `small-data-cluster` images to bootable USB drives.

> **Important:** Complete the following configuration steps before using the
> commands displayed in these `tmux` windows. Until the cluster configuration
> and required secrets have been created, the suggested build, virtualization,
> and flashing commands are not expected to work correctly. Do not run them yet.

### Configuring the `small-data-cluster`

This section explains the required and optional configuration settings available
within the project.

#### General Cluster Configuration

There are two supported ways to provide the cluster configuration:

1. An unencrypted `config.toml` file in the repository root
2. A SOPS-encrypted JSON file in the `secrets/` directory

The encrypted configuration is recommended for most deployments, particularly
when the repository is shared, backed up, or stored in Git. It allows sensitive
configuration values to be stored in encrypted form and makes it possible to
maintain a deployment-specific configuration alongside the project source code.

Using encrypted secrets introduces some additional setup and requires
appropriate decryption keys. However, this small administrative overhead
provides significantly better protection against accidentally exposing
passwords, API keys, and other credentials.

The unencrypted `config.toml` file may be suitable for temporary testing or for
a carefully controlled local environment. Use this option only after evaluating
the associated risks and ensuring that unauthorized users cannot access the
file, the repository, its backups, or the build machine.

> **Warning:** Never commit an unencrypted `config.toml` containing real
> credentials or other sensitive values to Git. Removing a secret in a later
> commit does not remove it from the repository’s history.

Encrypted files should also be handled carefully. Although SOPS protects the
encrypted values, filenames, configuration structure, metadata, and potentially
some unencrypted fields may remain visible. Ensure that only the intended
recipients possess the keys required to decrypt the file.

##### Using `config.toml`

Open the `config.toml` file in the root of the repository with an editor of your
choice, such as Vim, Helix (`hx`), Neovim, or Emacs.

The file will look similar to the following example:

```toml
[tailscale]
domain = "TS_DOMAIN"
authKey = "TS_AUTHKEY"
apiKey = "TS_APIKEY"

[headnode]
grafana_enable_admin = false
grafana_admin = "admin"
# This password is readable from the Nix store!
grafana_password = "admin"

[worker]
# If set to false, unique MAC-based hostnames will be used
acceptDHCPHostnames = false
# Workers will start their cluster services only after reaching the headnode
awaitHeadnode = true
# Show the system journal on tty1
showJournal = false
# Time in seconds to wait for the headnode before giving up
headnodeTimeout = 900

[users.alice]
passwordHash = "$6$niENrHi8EzNkxcQb$s0.Dc5HiGj3RyUEHIbi8sLZNBjA7Ibz1P2.odljSjYLlbjmX6n4d8B0lGEffjMEApf5rWqoU2Iq8fQiqWYGj71"
uid = 5001

sshKeys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPdCr/51y6xjnNRXXCH2MmLsXDopOB1w1Jjlx+/WQ+yK ture@tarantino alice@desktop",
  "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHCz3HYz0c6LM6CWIABw3iDg2QZgG1iBzaajGbiRF6L5b9KJ8vsQzWq2nh51+RXe26oCHT6Qw56pLsVf7de1WPM= alice@laptop"
]

[users.bob]
passwordHash = "$6$niENrHi8EzNkxcQb$s0.Dc5HiGj3RyUEHIbi8sLZNBjA7Ibz1P2.odljSjYLlbjmX6n4d8B0lGEffjMEApf5rWqoU2Iq8fQiqWYGj71"
uid = 5002

[telemetry]
enabled = true
```

The default `config.toml` included with the repository is not a functional
cluster configuration. It serves only as a template and contains placeholder
values that must be replaced before building or deploying the cluster.

Edit the file and save your changes. The updated configuration will be evaluated
the next time you execute a relevant Nix build command; no separate import step
is required.

The individual settings and the values that must be provided are explained in
the following sections.

> **Security warning:** Values from an unencrypted `config.toml` may become
> accessible through the build environment, generated images, build logs, or the
> Nix store. Do not assume that deleting the original configuration file after a
> build removes all copies of its contents.

##### Using an Encrypted JSON File

For improved protection of sensitive configuration values, you can create a
SOPS-encrypted JSON file in the `secrets/` directory.

Before creating an encrypted configuration, you must have an
[age](https://github.com/FiloSottile/age) identity at:

```text
~/.config/sops/age/keys.txt
```

On Linux, this is the default location in which SOPS searches for age
identities. The `age-keygen` command is already available in the project’s
development environment.

Create the required directory and generate a new key:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

The command generates a private age identity and prints its corresponding public
recipient key. The private identity begins with `AGE-SECRET-KEY-1` and must be
kept confidential. Do not commit `keys.txt` to Git, copy it into the project
repository, or share it with other users. Anyone who obtains this identity may
be able to decrypt secrets encrypted for it.

You can display the corresponding public recipient key again at any time by
running:

```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

The resulting public key begins with `age1` and may be shared. Sharing the
public recipient key does not reveal the private identity.

> **Advice:** Store a secure backup of `keys.txt`. If the private identity is
> lost and no other authorized identity can decrypt the secrets, the encrypted
> configuration cannot be recovered.

From the root of the repository, run:

```console
create-secret [--user USER] [--force]
```

By default, the secret-management tooling uses your current system username to
determine the name of the encrypted configuration file and to make the
appropriate secrets available to the Nix build environment.

You can use the `--user` option to specify a different configuration name:

```console
create-secret --user alice
```

The resulting file will be stored at:

```text
secrets/alice.json
```

When no `--user` option is provided, the file is normally created as:

```text
secrets/<system-username>.json
```

The command creates an encrypted copy of the configuration template located at:

```text
secrets/template.json
```

It then opens the new configuration in an editor so that you can replace the
template values with the settings and credentials required for your cluster. The
file is encrypted by SOPS when the editor is closed.

If a secrets file with the selected name already exists, the tool will normally
refuse to overwrite it. Use the `--force` option only when you intentionally
want to replace the existing file:

```console
create-secret --user alice --force
```

> **Warning:** Using `--force` may overwrite an existing encrypted
> configuration. Back up any values you still require before replacing the file.

When you enter the repository and its `direnv` environment is active, the
project’s secret-management tooling attempts to locate and decrypt the
configuration associated with your username. The decrypted values are made
available through your environment to Nix for builds that require access to
impure inputs.

In this context, an **impure build** is a Nix evaluation that is allowed to
access information outside the explicitly declared and locked flake inputs. This
is necessary because the decryption of the secrets can not happen at build time
or runtime due to how the `small-data-cluster` works.

> **Caution:** When the SOPS editor opens during `create-secret`, make at least
> one change before closing it. Closing the editor without modifying the
> template may prevent the encrypted file from being written correctly and can
> cause the command to fail.
>
> If this occurs, run `create-secret` again. Use `--force` when a partially
> created file already exists and you have confirmed that it is safe to replace.

You can make changes to your encrypted configuration by running
`sops secrets/username.json` from the repo root! If your json is invalid, you
will be promted to fix your issues or abort.

Do not manually decrypt the secrets file into the repository or save a plaintext
copy beside the encrypted file. Decrypted secrets may also remain temporarily
available in process environments, editor buffers, shell history, temporary
files, or build outputs. Restrict access to the build machine and close
applications containing sensitive values when they are no longer required.
