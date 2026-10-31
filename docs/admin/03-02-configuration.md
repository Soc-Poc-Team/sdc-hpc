## Configure the `small-data-cluster`

This section explains the required and optional configuration settings available
within the project.

### General cluster configuration

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

#### Use `config.toml`

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

#### Use an encrypted JSON file

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

```bash
create-secret [--user USER] [--force]
```

By default, the secret-management tooling uses your current system username to
determine the name of the encrypted configuration file and to make the
appropriate secrets available to the Nix build environment.

You can use the `--user` option to specify a different configuration name:

```bash
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

```bash
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
is necessary because the secrets cannot be decrypted at build time or runtime
due to how the `small-data-cluster` works.

> **Caution:** When the SOPS editor opens during `create-secret`, make at least
> one change before closing it. Closing the editor without modifying the
> template may prevent the encrypted file from being written correctly and can
> cause the command to fail.
>
> If this occurs, run `create-secret` again. Use `--force` when a partially
> created file already exists and you have confirmed that it is safe to replace.

You can edit your encrypted configuration by running
`sops secrets/<username>.json` from the repository root. If the JSON is invalid,
SOPS prompts you to correct the errors or abort.

Do not manually decrypt the secrets file into the repository or save a plaintext
copy beside the encrypted file. Decrypted secrets may also remain temporarily
available in process environments, editor buffers, shell history, temporary
files, or build outputs. Restrict access to the build machine and close
applications containing sensitive values when they are no longer required.

### Configuration options

The unencrypted `config.toml` file and the encrypted JSON configuration provide
the same logical configuration options. Only their syntax and storage format
differ.

Option names are case-sensitive and must be written exactly as documented below.
Values included in the configuration templates are placeholders and should not
be treated as secure or recommended defaults.

#### Tailscale configuration

The `tailscale` section configures the Tailscale network used to connect the
headnode, worker nodes, and authorized client devices.

| Option    | Type   | Description                                                            |
| --------- | ------ | ---------------------------------------------------------------------- |
| `domain`  | String | The Tailscale domain, also referred to as the tailnet DNS name.        |
| `authKey` | String | An authentication key used to register cluster nodes with the tailnet. |
| `apiKey`  | String | An API access token used by the project to call the Tailscale API.     |

> **Security warning:** The authentication key and API key are sensitive
> credentials. Do not publish them, include them in documentation, or commit
> them to Git in unencrypted form. Configure their permissions and expiration
> according to your organization’s security requirements.

#### Headnode configuration

The `headnode` section currently contains only options that control access to
the Grafana instance running on the headnode.

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

#### Worker configuration

The `worker` section controls the startup, identification, and diagnostic
behavior of worker nodes.

| Option                | Type    | Description                                                                                                                                                |
| --------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `acceptDHCPHostnames` | Boolean | Determines whether worker nodes use hostnames provided through DHCP. When set to `false`, unique hostnames derived from the nodes’ MAC addresses are used. |
| `awaitHeadnode`       | Boolean | Determines whether a worker node waits until the headnode is reachable before starting its cluster services.                                               |
| `showJournal`         | Boolean | Determines whether the system journal is displayed on the first virtual console, `tty1`.                                                                   |
| `headnodeTimeout`     | Integer | Specifies how many seconds a worker node waits for the headnode to become reachable before giving up.                                                      |

When `acceptDHCPHostnames` is disabled, a worker node’s identity depends on its
detected network interface and MAC address. Replacing a network adapter or
changing the interface detection order may therefore cause the node to receive a
different hostname.

> **Note:** The `acceptDHCPHostnames` feature is not currently stable or
> available. Set this option to `false`.

#### User configuration

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

#### Telemetry configuration

The `telemetry` section controls whether the project’s telemetry functionality
is enabled.

**About telemetry:**

This is a research project, so we are interested in gathering basic, anonymous
usage data to measure interest in it. The following is an example data point
periodically sent from each deployed cluster to our backend:

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

No other data is collected. You can opt out of telemetry by setting `enabled` to
`false`.

| Option    | Type    | Description                                                        |
| --------- | ------- | ------------------------------------------------------------------ |
| `enabled` | Boolean | Enables or disables telemetry collection and its related services. |

### Required configuration

This section summarizes the configuration values that must be provided before
you can continue with the deployment guide.

#### Tailscale credentials

The cluster configuration requires three Tailscale values:

- `domain`
- `authKey`
- `apiKey`

The following procedure uses the hosted Tailscale service and its web-based
[admin console](https://login.tailscale.com/admin). Interface labels can change,
but the required policy and credentials remain the same.

##### Create or select the tailnet

1. Sign in to the [Tailscale admin console](https://login.tailscale.com/admin)
   with the identity that will administer the cluster network. Signing in for
   the first time creates a tailnet.
2. Verify the selected tailnet in the admin console before changing its policy.
   An account can administer more than one tailnet.
3. Install Tailscale on the workstation from which you will administer the
   cluster, and sign that workstation in to the same tailnet. Use the normal
   interactive login for an administrator's workstation;

Tailnet Owners, Admins, and Network admins can edit the tailnet policy. The
ability to create keys also depends on the administrator's Tailscale role. See
the official
[Tailscale API documentation](https://tailscale.com/docs/reference/tailscale-api)
and
[auth key documentation](https://tailscale.com/docs/features/access-control/auth-keys)
for the current role requirements.

##### Enable name resolution and record the domain

The project uses Tailscale names rather than fixed IP addresses. For example,
workers contact Slurm, NFS, Dask, Prometheus, Loki, and JupyterHub through the
headnode's Tailscale name.

1. Open **DNS** in the admin console.
2. Ensure that **MagicDNS** is enabled. New tailnets normally enable it by
   default, but you must verify the setting.
3. Find the **Tailnet DNS name**. It resembles `tail1234.ts.net` or a generated
   name such as `yak-bebop.ts.net`.
4. Copy this complete DNS name into the configuration's `domain` option. Do not
   include a protocol, hostname, port, slash, or quotation marks inside the
   value.

For example:

```toml
[tailscale]
domain = "yak-bebop.ts.net"
```

Do not use the tailnet display name in this field. The display name is a label
for people; the DNS name is the suffix used to form addresses such as
`headnode.yak-bebop.ts.net`. Refer to the official
[MagicDNS documentation](https://tailscale.com/docs/features/magicdns) for more
information about Tailscale name resolution.

##### Configure the tailnet policy

Tailscale denies connections that are not permitted by the tailnet policy. The
cluster needs two types of communication:

- Cluster nodes must be able to initiate connections to other cluster nodes.
- Authorized administrators' Tailscale devices must be able to reach cluster
  nodes.

Use a tag to give all cluster nodes one non-human device identity. The reusable
authentication key created later applies this tag during enrollment. Keep
administrator workstations associated with their human Tailscale identities so
that removing a person from the administrator group also removes their access.

Open **Access controls** in the admin console and select the JSON editor.
Tailscale calls the policy format _HuJSON_, short for human JSON. It extends
JSON with conveniences such as comments and trailing commas. If this is a new
tailnet used only for the cluster, replace the default policy with the following
policy. Replace `admin@example.com` with the exact identity shown for your
administrator in Tailscale:

```json
{
  "groups": {
    "group:sdc-admins": [
      "admin@example.com"
    ]
  },

  "tagOwners": {
    "tag:cluster": [
      "group:sdc-admins"
    ]
  },

  "grants": [
    {
      // Cluster services communicate across several ports and protocols.
      "src": ["tag:cluster"],
      "dst": ["tag:cluster"],
      "ip": ["*"]
    },
    {
      // Administrators reach the cluster.
      "src": ["group:sdc-admins"],
      "dst": ["tag:cluster"],
      "ip": ["*"]
    }
  ],

  "nodeAttrs": [
    {
      // Keep cluster nodes in one identifiable Tailscale address range.
      "target": ["tag:cluster"],
      "ipPool": ["100.81.0.0/24"]
    }
  ]
}
```

Add every Tailscale identity that should administer the cluster to
`group:sdc-admins`. Use the exact login identifiers displayed by Tailscale.
Depending on the identity provider, an identifier may look like an email address
or a GitHub identity such as `username@github`.

This example deliberately uses Tailscale
[grants](https://tailscale.com/docs/features/access-control/grants), which are
the recommended replacement for older ACL rules.

> **Security warning:** The example permits all network protocols and ports
> between cluster nodes and from the administrator group to cluster nodes. This
> matches the project's dynamic services and administrative model, but it gives
> those identities broad network access. Do not add ordinary users to
> `group:sdc-admins`. If you restrict the ports further, test every cluster
> service and Slurm's configured dynamic port range before deployment.

If the tailnet also contains unrelated devices, do not replace its complete
policy. Merge the `group:sdc-admins`, `tag:cluster`, and grant entries into the
existing policy. Review the resulting permissions in the policy editor before
saving. A policy change applies to the whole tailnet and can interrupt existing
services outside this project.

The project uses the normal OpenSSH service over the Tailscale network. It does
not enable Tailscale SSH in its `tailscale up` command. A Tailscale `ssh` policy
section is therefore not required for the documented deployment. The network
grant still permits the OpenSSH connection to TCP port 22, and the Linux
account's password or authorized SSH key performs the login authentication.

Save the policy only after the editor reports that it is valid. Tailscale's
[tailnet policy documentation](https://tailscale.com/docs/features/tailnet-policy-file)
explains how to preview effective permissions before applying changes.

##### Assign the cluster IP pool

The policy above assigns cluster nodes addresses from `100.81.0.0/24`. We
recommend using a dedicated pool because it keeps cluster addresses in one
identifiable range and separates them from other Tailscale devices. Tag-based
grants and MagicDNS remain the primary means of identifying and addressing
nodes. Do not assume that a node retains one particular address across boots.

When merging the cluster rules into an existing tailnet policy, include the
following top-level entry:

```json
"nodeAttrs": [
  {
    "target": ["tag:cluster"],
    "ipPool": ["100.81.0.0/24"]
  }
]
```

Before saving the policy, confirm that `100.81.0.0/24` does not overlap another
Tailscale IP pool or a network used by your organization. If it does, choose a
different suitable range and update the policy consistently. Tailscale IP pools
must be subsets of `100.64.0.0/10`, and some subranges are reserved. IP pools
are currently a beta Tailscale feature. Check the current restrictions in the
official [IP pool documentation](https://tailscale.com/docs/reference/ip-pool)
before selecting the range.

##### Generate the cluster authentication key

Define and save `tag:cluster` in the policy before creating the key. The tag is
then available in the key form.

1. Open **Keys** in the admin console.
2. In **Auth keys**, select **Generate auth key**.
3. Enter a description that identifies the deployment and intended rotation
   date.
4. Enable **Reusable**. One key must enroll the headnode and all worker nodes,
   including later boots of those live images.
5. Enable **Ephemeral**. The cluster boots without persistent Tailscale state,
   and ephemeral enrollment allows Tailscale to remove inactive node records.
6. Enable **Pre-approved** if the tailnet uses device approval. This option is
   displayed only when device approval is enabled.
7. Add `tag:cluster` under **Tags**.
8. Select an expiration period and record its date. Tailscale auth keys expire
   after 1 to 90 days.
9. Select **Generate key**, copy the complete value immediately, and store it in
   the selected cluster secrets configuration as `authKey`.

An authentication key normally starts with `tskey-auth`. It is case-sensitive
and is displayed in full only when generated.

> **Security warning:** A reusable authentication key allows anyone who obtains
> it to enroll additional devices with `tag:cluster` until the key expires or is
> revoked. Such a device receives the network permissions assigned to the tag.
> Store the key as a secret and revoke it immediately if exposure is suspected.

The combination of **Reusable**, **Ephemeral**, and `tag:cluster` is specific to
the project's boot model. A one-off key can enroll only one node. A non-reusable
key therefore cannot support a cluster image that boots on several machines or
reenrolls after shutdown.

##### Generate the API access token

The current implementation expects a Tailscale API access token, historically
called an API key. It does not implement the OAuth client flow.

1. Remain on **Keys**.
2. In **API access tokens**, select **Generate access token**.
3. Enter a description that identifies the cluster and intended rotation date.
4. Select an expiration period from 1 to 90 days and record its date.
5. Generate the token, copy it immediately, and store it in the selected cluster
   secrets configuration as `apiKey`.

An API access token normally starts with `tskey-api`. It is case-sensitive and
is displayed in full only once. The project uses it to list the tailnet's
devices and delete matching device records through the Tailscale API.

> **Security warning:** A Tailscale API access token has broad access to the
> tailnet API. The project embeds it into the generated system configuration so
> the cleanup service can use it during boot. Treat the build machine, secret
> configuration, generated images, and Nix store as sensitive. Tailscale offers
> more narrowly scoped trust credentials, but the current project does not yet
> implement the token exchange required to use them.

##### Complete the project configuration

Enter the DNS name and both newly generated secrets in the same selected
configuration backend. For an unencrypted test configuration, the result has
this form:

```toml
[tailscale]
domain = "yak-bebop.ts.net"
authKey = "<TAILSCALE_AUTH_KEY>"
apiKey = "<TAILSCALE_API_ACCESS_TOKEN>"
```

Replace every placeholder. Do not commit real values in `config.toml`. For a
deployment, prefer the encrypted SOPS configuration described in
[Use an encrypted JSON file](#use-an-encrypted-json-file).

Before building, verify that:

- `domain` contains the tailnet DNS name and not its display name.
- `authKey` is the reusable, ephemeral key carrying `tag:cluster`.
- `apiKey` is the API access token, not another authentication key.
- Neither key is expired or revoked.
- The saved tailnet policy permits `tag:cluster` to reach itself.
- The administrator identity can reach `tag:cluster`.

##### Plan credential rotation

Both Tailscale credentials expire no later than 90 days after generation. Track
both expiration dates outside the volatile cluster. Generate replacements before
the earlier date, update the encrypted configuration, rebuild all node images,
and reflash the cluster as one consistent deployment.

An expired authentication key does not immediately disconnect nodes that are
already running, and revoking it does not deauthorize devices previously
enrolled with it. However, the next boot starts without retained Tailscale state
and must enroll again. An expired API token also prevents the cleanup service
from completing. Do not shut down a cluster for planned maintenance until its
replacement images contain valid credentials.

If either credential is exposed, revoke it from **Keys**, create a replacement,
rebuild the images, and replace the affected deployment. Review the **Machines**
page for unauthorized devices and delete any that should not be present. Refer
to Tailscale's
[key and secret management guidance](https://tailscale.com/docs/reference/key-secret-management)
for current rotation and revocation behavior.

#### Grafana credentials

The Grafana administrator account is primarily required for development,
troubleshooting, and changes to the Grafana configuration.

For regular cluster use, you can disable administrator access through the
`grafana_enable_admin` option without affecting the dashboards and monitoring
functionality available to ordinary users.

When administrator access is enabled, replace the template username and password
with deployment-specific credentials. Do not reuse the Grafana password for any
other account or service. Remember that the configured password is readable from
the Nix store and generated build artifacts.

#### User accounts

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

**Generate a password hash**

The project development shell provides the `mkpasswd` command. Generate a
SHA-512 crypt password hash by running:

```bash
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

**Add SSH keys**

To enable SSH key authentication, add the user’s public SSH keys to `sshKeys`.
Public keys commonly begin with identifiers such as `ssh-ed25519` or
`ecdsa-sha2-nistp256`.

Never add a private SSH key to the cluster configuration. Private keys must
remain exclusively on the client devices from which users connect.

> **Important:** Users cannot be added or removed at runtime through an
> administrative interface or the command line. User management is intentionally
> declarative: all required accounts must be defined before the images are
> built.
>
> Adding, removing, or changing a user requires updating the configuration,
> rebuilding the affected images, and redeploying them. The `small-data-cluster`
> is not designed to support dynamic runtime user administration.

### Configure the flash tool

The flash tool writes the generated worker ISO image to one or more authorized
USB drives. Because this process overwrites the selected devices completely, the
tool uses an authorization file to restrict which drives it may access.

You will flash the images as the final step before deployment. You may skip this
section for now and return to it after building the images.

> **Warning:** Flashing a device destroys its existing partition table,
> filesystems, and data. Carefully verify every device identifier before adding
> it to the authorization file. Disconnect unrelated USB storage devices
> whenever possible.

The authorization file contains one device identifier per line. These
identifiers correspond to entries under `/dev/disk/by-id/` and must be provided
without the `/dev/disk/by-id/` prefix.

Using identifiers from `/dev/disk/by-id/` is safer than directly using names
such as `/dev/sdb`, because names under `/dev/sd*` may change when devices are
connected, removed, or detected in a different order.

#### Identify USB drives

Connect the USB drives that you intend to use and inspect the available block
devices:

```bash
lsblk -o NAME,PATH,MODEL,SERIAL,TRAN,SIZE,TYPE,MOUNTPOINTS
```

Use the model, serial number, capacity, transport type, and mounted filesystems
to identify each intended target.

You can then list the persistent identifiers assigned to USB storage devices:

```bash
for device in /dev/disk/by-id/usb-*; do
  [[ "$device" == *-part* ]] && continue
  printf '%s -> %s\n' "$(basename "$device")" "$(readlink -f "$device")"
done
```

The output shows each USB identifier and the corresponding device under `/dev`,
for example:

```text
usb-USB_SanDisk_3.2Gen1_00010501092224214341-0:0 -> /dev/sdb
```

Copy only the identifier on the left-hand side. Do not include the `-> /dev/sdX`
portion.

Entries ending in suffixes such as `-part1` identify individual partitions
rather than complete drives and must not be added to the authorization file. The
flash tool must write to the complete device.

Be particularly careful with generic card-reader identifiers such as:

```text
usb-Generic-_SD_MMC_CRW_28203008282014000-0:0
```

Such an identifier may refer to an SD-card reader rather than a permanently
attached storage device. Authorize it only when you have confirmed that the
inserted card is an intended flashing target.

#### Create the authorization file

Add one verified device identifier per line to:

```text
dev/.write_authorization
```

For example, a file authorizing several USB drives may contain:

```text
usb-USB_SanDisk_3.2Gen1_00010501092224214341-0:0
usb-USB_SanDisk_3.2Gen1_00010505092224214333-0:0
usb-USB_SanDisk_3.2Gen1_00016409092224213732-0:0
```

The entries must match the filenames under `/dev/disk/by-id/` exactly. Blank
lines or shortened identifiers should not be used.

Only add drives that are dedicated to the `small-data-cluster`. Remove an entry
when the corresponding device should no longer be writable by the flash tool.

> **Important:** The authorization file reduces the risk of accidentally writing
> to an unrelated device, but it does not verify the physical identity or
> current contents of a drive. You remain responsible for confirming that every
> authorized identifier belongs to the intended target.

#### Verify the script paths

The flash script uses relative paths for both the ISO image and the
authorization file. In the provided script, these are configured as:

```bash
ISO="results/worker/iso/workernode.iso"
AUTH_FILE=".write_authorization"
```

Relative paths are resolved from the directory in which the script is executed,
not necessarily from the directory containing the script.

When the authorization file is stored at `dev/.write_authorization` and the
script is started from the repository root, configure the script to use:

```bash
AUTH_FILE="dev/.write_authorization"
```

The ISO path assumes that the generated worker image exists at the location
where the `build-batch` script places it:

```text
results/worker/iso/workernode.iso
```

Ensure that the image has finished building before attempting to flash any
drives.

#### Perform a dry run

You may perform a dry run before writing to the USB drives:

```bash
./dev/flash.sh --dry
```

The dry run lists the authorized devices and displays the `dd` commands that
would be executed without modifying the drives.

Review the output carefully and confirm that:

- Every listed device is an intended target.
- No internal disk or unrelated external drive appears.
- The device identifiers match the authorization file.
- The worker ISO path is correct.
- The selected devices have the expected model and capacity.

The script silently ignores connected USB devices that are not present in the
authorization file.

#### Flash the authorized drives

After confirming the dry-run output, execute the script without `--dry`:

```bash
./dev/flash.sh
```

The script uses `sudo dd` to write the worker ISO to every connected and
authorized device. Multiple authorized drives are written concurrently.

You may be prompted for your `sudo` password. Do not disconnect a drive, shut
down the build machine, or interrupt the script while writing is in progress.

The script waits until all writing operations have completed and uses `sync` to
ensure that buffered data is written to the devices before returning.

Before flashing, unmount any mounted partitions belonging to the target drives.
Their mount points can be identified using `lsblk`. A mounted partition can be
unmounted with:

```bash
sudo umount /dev/sdX1
```

Replace `/dev/sdX1` with the actual partition shown by `lsblk`. Do not unmount
or write to a device unless you have positively identified it.

After the script completes, allow the system to finish processing the devices
before physically removing them. The resulting USB drives can then be used to
boot the worker nodes.
