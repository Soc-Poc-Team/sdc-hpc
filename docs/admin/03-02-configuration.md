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

#### Configuration options

The unencrypted `config.toml` file and the encrypted JSON configuration provide
the same logical configuration options. Only their syntax and storage format
differ.

Option names are case-sensitive and must be written exactly as documented below.
Values included in the configuration templates are placeholders and should not
be treated as secure or recommended defaults.

##### Tailscale Configuration

The `tailscale` section configures the Tailscale network used to connect the
headnode, workernodes, and authorized client devices.

| Option    | Type   | Description                                                            |
| --------- | ------ | ---------------------------------------------------------------------- |
| `domain`  | String | The Tailscale domain, also referred to as the tailnet DNS name.        |
| `authKey` | String | An authentication key used to register cluster nodes with the tailnet. |
| `apiKey`  | String | An API key used by the project to interact with the Tailscale API.     |

> **Security warning:** The authentication key and API key are sensitive
> credentials. Do not publish them, include them in documentation, or commit
> them to Git in unencrypted form. Configure their permissions and expiration
> according to your organization’s security requirements.

##### Headnode Configuration

The `headnode` section currently only has options regarding access to the
Grafana instance running on the headnode.

| Option                 | Type    | Description                                                                 |
| ---------------------- | ------- | --------------------------------------------------------------------------- |
| `grafana_enable_admin` | Boolean | Enables or disables access to the configured Grafana administrator account. |
| `grafana_admin`        | String  | Sets the username of the Grafana administrator account.                     |
| `grafana_password`     | String  | Sets the password of the Grafana administrator account.                     |

> **Warning:** The Grafana administrator password may be readable from the Nix
> store or generated build artifacts. Do not reuse a password that protects any
> other account or system. Administrative access should remain disabled unless
> it is explicitly required.

The password included in the configuration template is insecure and must be
replaced before deployment.

##### Workernode Configuration

The `worker` section controls the startup, identification, and diagnostic
behavior of workernodes.

| Option                | Type    | Description                                                                                                                                               |
| --------------------- | ------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `acceptDHCPHostnames` | Boolean | Determines whether workernodes use hostnames provided through DHCP. When set to `false`, unique hostnames derived from the nodes’ MAC addresses are used. |
| `awaitHeadnode`       | Boolean | Determines whether a workernode waits until the headnode is reachable before starting its cluster services.                                               |
| `showJournal`         | Boolean | Determines whether the system journal is displayed on the first virtual console, `tty1`.                                                                  |
| `headnodeTimeout`     | Integer | Specifies how many seconds a workernode waits for the headnode to become reachable before giving up.                                                      |

When `acceptDHCPHostnames` is disabled, a workernode’s identity depends on its
detected network interface and MAC address. Replacing a network adapter or
changing the interface detection order may therefore cause the node to receive a
different hostname.

> **Note:** the "acceptDHCPHostnames" feature is currently not stable and
> therefore not available. Set this option to `false`!

##### User Configuration

The `users` section defines the user accounts created on the cluster. Each child
entry beneath `users` represents one account, and the entry name becomes the
username.

| Option         | Type             | Description                                                                                                                       |
| -------------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `passwordHash` | String           | The cryptographic hash of the user’s login password. Plaintext passwords must not be entered here.                                |
| `uid`          | Integer          | The numeric user ID assigned to the account. It is uniquely shared within the cluster.                                            |
| `sshKeys`      | Array of strings | A list of public SSH keys authorized to access the user account. This option may be omitted when no SSH keys should be installed. |

Additional accounts can be created by adding further entries beneath `users`.
Both usernames and numeric user IDs must be unique.

> **Security warning:** `passwordHash` must contain a password hash, not the
> original password. The hash included in the configuration template is public
> and must not be used in a real deployment.

##### Telemetry Configuration

The `telemetry` section controls whether the project’s telemetry functionality
is enabled.

_About Telemetry:_

This is a research project. Thus we are interested in gathering basic, anonymous
usage data to measure interest in this project. Example datapoint that we
periodically send on each deployed cluster to our backend:

```json
{
  "type": "de.fh-aachen.bigdata.hpc-on-demand-telemetry",
  "cluster": "1745849932",
  "nodes": [
    {
      "cores": 2,
      "cpu_load": 27,
      "free_mem": 7527,
      "cpus": 2,
      "sockets": 1,
      "last_busy": 1745849940,
      "hostname": "headnode",
      "real_memory": 11679,
      "alloc_memory": 0,
      "alloc_cpus": 0,
      "alloc_idle_cpus": 2,
      "slurmd_start_time": 1745849940,
      "tres": "cpu=2,mem=11679M,billing=2",
      "version": "23.11.10",
      "state": ["IDLE", "DYNAMIC_NORM"],
      "reason": "",
      "reason_set_by_user": "root",
      "reason_changed_at": {
        "set": true,
        "infinite": false,
        "number": 0
      }
    }
  ]
}
```

**We do not gather any other data. Telemetry can be opted out!**

| Option    | Type    | Description                                                        |
| --------- | ------- | ------------------------------------------------------------------ |
| `enabled` | Boolean | Enables or disables telemetry collection and its related services. |

#### What You Need to Configure

This section summarizes the configuration values that must be provided before
you can continue with the deployment guide.

##### Tailscale Credentials

You must provide all three options in the `tailscale` section:

- `domain`
- `authKey`
- `apiKey`

If you followed the earlier instructions, you should already have a Tailscale
account and access to a tailnet.

The authentication key is used to register cluster nodes with the tailnet
without requiring an interactive login. The API key allows the project to
interact with the Tailscale API, while the domain identifies the tailnet used by
the cluster. These credentials must be treated as secrets and must not be
committed to the repository in unencrypted form.

**TODO:** Add instructions for generating the Tailscale authentication and API
keys. This section must also explain how to configure the tailnet’s access rules
so that the headnode and workernodes can communicate as required. Tailscale
recommends using grants for new access-policy configurations.

##### Grafana Credentials

The Grafana administrator account is primarily required for development,
troubleshooting, and changes to the Grafana configuration.

For regular cluster use, you can disable administrator access through the
`grafana_enable_admin` option without affecting the dashboards and monitoring
functionality available to ordinary users.

When administrator access is enabled, replace the template username and password
with deployment-specific credentials. Do not reuse the Grafana password for any
other account or service. Remember that the configured password is readable from
the Nix store and generated build artifacts.

##### User Accounts

At least one complete entry must be added to the `users` section before building
the cluster. Without a configured user account, you will not be able to sign in
and use the deployed system.

The configured accounts are used for both:

- JupyterHub, which is the primary interface intended for less-experienced
  cluster users
- SSH access to the cluster nodes

Each configured user corresponds to an actual operating-system account created
on **every node** in the cluster. A user entry requires:

- A unique username
- A unique numeric user ID in `uid`
- A password hash in `passwordHash`
- Optionally, one or more public SSH keys in `sshKeys`

Usernames and UIDs must remain consistent across the cluster because shared file
ownership and permissions are associated with numeric UIDs.

###### Generating a Password Hash

The project development shell provides the `mkpasswd` command. Generate a
SHA-512 crypt password hash by running:

```console
mkpasswd --method=sha-512
```

Enter the intended password when prompted. The command prints a salted password
hash beginning with `$6$`. Copy the complete output into the user’s
`passwordHash` option. Do not provide the password directly as a command-line
argument. Entering it at the prompt prevents the plaintext password from being
stored in your shell history or exposed as part of the command line.

The password hash is not the plaintext password, but it should still be treated
as sensitive information. Anyone who obtains it can attempt to recover the
password through offline guessing attacks. Use a strong, unique password and
store the hash only in the selected cluster configuration.

###### Adding SSH Keys

To enable SSH key authentication, add the user’s public SSH keys to `sshKeys`.
Public keys commonly begin with identifiers such as `ssh-ed25519` or
`ecdsa-sha2-nistp256`.

Never add a private SSH key to the cluster configuration. Private keys must
remain exclusively on the client devices from which users connect.

> **Important:** Users cannot be added or removed at runtime through an
> administrative interface or the command line etc. User management is
> intentionally declarative: all required accounts must be defined before the
> images are built.
>
> Adding, removing, or changing a user requires updating the configuration,
> rebuilding the affected images, and redeploying them. The `small-data-cluster`
> is not designed to support dynamic runtime user administration.
