## Configuring the `small-data-cluster`

This section explains the required and optional configuration settings available
within the project.

### General Cluster Configuration

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

#### Using `config.toml`

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

#### Using an Encrypted JSON File

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
