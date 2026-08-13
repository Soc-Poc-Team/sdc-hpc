# Getting started

This chapter describes the recommended workflow for getting started with the
`small-data-cluster`.

## Prerequisites

Before you start development, ensure that you have:

- A Nix-enabled workstation. See the administration manual for instructions on
  setting up a suitable workstation.
- Working knowledge of Git and its basic workflow.
- A general understanding of the Nix language and the Nix package ecosystem.

## Set up Tailscale

[Tailscale](https://tailscale.com/) is a networking service that creates a
private mesh virtual private network (VPN) between authorized devices. A
Tailscale network is called a _tailnet_. The `small-data-cluster` uses a tailnet
to connect the headnode, worker nodes, and developer workstations.

The project configuration requires three Tailscale values:

- `domain`
- `authKey`
- `apiKey`

The following procedure uses the hosted Tailscale service and its web-based
[admin console](https://login.tailscale.com/admin). Interface labels can change,
but the required policy and credentials remain the same.

### Create or select the tailnet

1. Sign in to the [Tailscale admin console](https://login.tailscale.com/admin)
   with the identity that will administer the development cluster network.
   Signing in for the first time creates a tailnet.
2. Verify the selected tailnet in the admin console before changing its policy.
   An account can administer more than one tailnet.
3. Install Tailscale on the workstation from which you will develop and
   administer the cluster, and sign that workstation in to the same tailnet. Use
   the normal interactive login for a developer workstation.

Tailnet Owners, Admins, and Network admins can edit the tailnet policy. The
ability to create keys also depends on the administrator's Tailscale role. See
the official
[Tailscale API documentation](https://tailscale.com/docs/reference/tailscale-api)
and
[auth key documentation](https://tailscale.com/docs/features/access-control/auth-keys)
for the current role requirements.

### Enable name resolution and record the domain

The project uses Tailscale names rather than fixed IP addresses. Workers contact
services on the headnode though the headnode's Tailscale name.

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

### Configure the tailnet policy

Tailscale denies connections that are not permitted by the tailnet policy. The
cluster needs two types of communication:

- Cluster nodes must be able to initiate connections to other cluster nodes.
- Authorized developers' Tailscale devices must be able to reach cluster nodes.

Use a tag to give all cluster nodes one non-human device identity. The reusable
authentication key created later applies this tag during enrollment. Keep
developer workstations associated with their human Tailscale identities so that
removing a person from the developer group also removes their access.

Open **Access controls** in the admin console and select the JSON editor.
Tailscale calls the policy format _HuJSON_, short for human JSON. It extends
JSON with conveniences such as comments and trailing commas. If this is a new
tailnet used only for the cluster, replace the default policy with the following
policy. Replace `developer@example.com` with the exact identity shown for your
developer in Tailscale:

```json
{
  "groups": {
    "group:sdc-developers": [
      "developer@example.com"
    ]
  },

  "tagOwners": {
    "tag:cluster": [
      "group:sdc-developers"
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
      // Developers reach the cluster.
      "src": ["group:sdc-developers"],
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

Add every Tailscale identity that should develop or administer the cluster to
`group:sdc-developers`. Use the exact login identifiers displayed by Tailscale.
Depending on the identity provider, an identifier may look like an email address
or a GitHub identity such as `username@github`.

This example uses Tailscale
[grants](https://tailscale.com/docs/features/access-control/grants), which are
the recommended replacement for older ACL rules.

If the tailnet also contains unrelated devices, do not replace its complete
policy. Merge the `group:sdc-developers`, `tag:cluster`, and grant entries into
the existing policy. Review the resulting permissions before saving. A policy
change applies to the whole tailnet and can interrupt services outside this
project.

The project uses the normal OpenSSH service over the Tailscale network. It does
not enable Tailscale SSH in its `tailscale up` command. A Tailscale `ssh` policy
section is therefore not required. The network grant permits the OpenSSH
connection to TCP port 22, and the Linux account's password or authorized SSH
key performs login authentication.

Save the policy only after the editor reports that it is valid. Tailscale's
[tailnet policy documentation](https://tailscale.com/docs/features/tailnet-policy-file)
explains how to preview effective permissions before applying changes.

### Assign the cluster IP pool

The policy above assigns cluster nodes addresses from `100.81.0.0/24`. A
dedicated pool keeps cluster addresses in one identifiable range and separates
them from other Tailscale devices. Tag-based grants and MagicDNS remain the
primary means of identifying and addressing nodes. Do not assume that a node
retains one particular address across boots.

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

### Generate the cluster authentication key

Define and save `tag:cluster` in the policy before creating the key. The tag is
then available in the key form.

1. Open **Keys** in the admin console.
2. In **Auth keys**, select **Generate auth key**.
3. Enter a description that identifies the development cluster and intended
   rotation date.
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
   the selected developer secrets configuration as `authKey`.

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

### Generate the API access token

The current implementation expects a Tailscale API access token, historically
called an API key. It does not implement the OAuth client flow.

1. Remain on **Keys**.
2. In **API access tokens**, select **Generate access token**.
3. Enter a description that identifies the development cluster and intended
   rotation date.
4. Select an expiration period from 1 to 90 days and record its date.
5. Generate the token, copy it immediately, and store it in the selected
   developer secrets configuration as `apiKey`.

An API access token normally starts with `tskey-api`. It is case-sensitive and
is displayed in full only once. The project uses it to list the tailnet's
devices and delete matching device records through the Tailscale API.

> **Security warning:** A Tailscale API access token has broad access to the
> tailnet API. The project embeds it into the generated system configuration so
> the cleanup service can use it during boot. Treat the development workstation,
> secret configuration, generated images, and Nix store as sensitive. Tailscale
> offers more narrowly scoped trust credentials, but the project does not yet
> implement the token exchange required to use them.

### Complete the developer configuration

Enter the DNS name and both newly generated secrets in the same selected
configuration backend. For an unencrypted test configuration, the result has
this form:

```toml
[tailscale]
domain = "yak-bebop.ts.net"
authKey = "<TAILSCALE_AUTH_KEY>"
apiKey = "<TAILSCALE_API_ACCESS_TOKEN>"
```

Replace every placeholder. Do not commit real values in `config.toml`. For
development with real credentials, use the SOPS-encrypted configuration loaded
by `direnv` as described later in this chapter.

Before building, verify that:

- `domain` contains the tailnet DNS name and not its display name.
- `authKey` is the reusable, ephemeral key carrying `tag:cluster`.
- `apiKey` is the API access token, not another authentication key.
- Neither key is expired or revoked.
- The saved tailnet policy permits `tag:cluster` to reach itself.
- The developer identity can reach `tag:cluster`.

### Plan credential rotation

Both Tailscale credentials expire no later than 90 days after generation. Track
both expiration dates outside the volatile cluster. Generate replacements before
the earlier date, update the encrypted configuration, rebuild all node images,
and replace the development cluster as one consistent deployment.

An expired authentication key does not immediately disconnect nodes that are
already running, and revoking it does not deauthorize devices previously
enrolled with it. However, the next boot starts without retained Tailscale state
and must enroll again. An expired API token also prevents the cleanup service
from completing. Check the credentials before starting a planned test session.

If either credential is exposed, revoke it from **Keys**, create a replacement,
rebuild the images, and replace the affected development deployment. Review the
**Machines** page for unauthorized devices and delete any that should not be
present. Refer to Tailscale's
[key and secret management guidance](https://tailscale.com/docs/reference/key-secret-management)
for current rotation and revocation behavior.

### Use the development utility

**TODO:** This may be moved to a "utilities chapter" instead.

The `.envrc` described in the next section exports `TAILSCALE_APIKEY` and
`TAILSCALE_DOMAIN` from the decrypted developer configuration. The
`dev/tailscale-tidy.py` utility uses these variables to list the tailnet's
device records:

```bash
./dev/tailscale-tidy.py list
```

It can also delete every device record whose hostname exactly matches the
argument:

```bash
./dev/tailscale-tidy.py delete <hostname>
```

Replace `<hostname>` with the exact name shown by the `list` command.

> **Caution:** The `delete` command modifies the selected tailnet immediately
> and does not ask for confirmation. Verify `TAILSCALE_DOMAIN`, the exact
> hostname, and the matching record before running it.

Access to the tailnet is not required for every source-only task. You can
inspect and format Nix code or render documentation without connecting to a
running cluster. Tailscale access is required when testing communication between
nodes, accessing cluster services, or using utilities that call its API.

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
secret-management system. Without `direnv`, you must enter the development
environment manually and provide any required secret configuration before
running an impure build.

You can install `direnv` using your operating system's package manager. On a
Nix-enabled system, you can install it for the current user with:

```bash
nix profile install nixpkgs#direnv
```

The `nix profile install` command adds the selected package to the user's Nix
profile.

> **Note:** For a reproducible setup, you may prefer to add `direnv` to your
> declarative system or home configuration instead of using
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

Fish is the default shell on the `small-data-cluster`. Add the hook to your Fish
configuration file at `~/.config/fish/config.fish`:

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

We will return to this after cloning the repository, when the instructions ask
you to enter the cloned directory and run `direnv allow`.

### Understand the project environment

The repository's `.envrc` performs the following actions whenever `direnv` loads
it:

1. Watches files under `secrets/` so that a change reloads the environment.
2. Loads the default flake development shell with impure evaluation enabled.
3. Selects `secrets/<username>.json` for the current system user when that file
   exists.
4. Decrypts the selected file with SOPS and exports its compact JSON as
   `SDC_SECRETS`.
5. Exports the configured Tailscale API token and domain as `TAILSCALE_APIKEY`
   and `TAILSCALE_DOMAIN` for development utilities.
6. Creates the prepared `small-data-cluster` `tmux` session when it does not
   already exist.

The `SDC_SECRETS` variable changes how `flake.nix` obtains `userConfig`. When
the variable is present, the flake parses its JSON value instead of reading
`config.toml`. Nix can read this environment variable only during impure
evaluation.

> **Security warning:** Decrypted credentials are present in the environment of
> commands started from the authorized shell. They may also become part of the
> Nix store and generated images during evaluation and builds. Do not print the
> variables, copy them into logs, or expose the environment to untrusted
> processes.

If no matching secret file exists, `.envrc` prints instructions for creating one
and continues loading the development environment. Pure operations that use
`config.toml` may still work, but impure builds will not receive a
deployment-specific configuration through `SDC_SECRETS`.

## Check out the repository

The `small-data-cluster` is hosted in two repositories on separate GitLab
instances operated by FH Aachen.

The primary repository is hosted on the FH Aachen enterprise GitLab instance:

[Primary `small-data-cluster` repository](https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster)

This repository contains project metadata, including work items, and should
remain private.

A public mirror is hosted on the FH Aachen Community GitLab instance:

[Public `hpc-on-demand` mirror](https://git-ce.fh-aachen.de/bigdatalab/hpc-on-demand)

The repositories currently use different names because the final project name
has not yet been decided.

The primary repository is configured to push-mirror all commits from all
branches to the public repository. The mirror uses a deployment token from the
Community GitLab instance.

> **Security warning:** Commits pushed to the private primary repository are
> mirrored to the public repository. Do not commit or push credentials, private
> information, internal work-item content, or other data that must not become
> public.

> **Warning:** Do not push directly to the public mirror. Direct changes can
> cause the configured push mirror to fail, including changes that appear not to
> conflict with the primary repository.

Clone the primary `small-data-cluster` repository to your Nix-enabled
workstation:

```bash
git clone https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster.git
```

Alternatively, clone the repository over SSH:

```bash
git clone git@git.fh-aachen.de:bigdata/cape-canaveral/small-data-cluster.git
```

> **Note:** SSH access requires connecting from inside the FH Aachen network.
> Use HTTPS when working outside that network.

## Activate the development shell

Enter the cloned repository:

```bash
cd small-data-cluster
```

Because the repository's `.envrc` has not been authorized yet, `direnv` prints a
message similar to:

```text
direnv: error /path/to/small-data-cluster/.envrc is blocked. Run `direnv allow` to approve its content
```

Review `.envrc` before authorizing it. The file executes commands on your
workstation and loads the flake with impure evaluation enabled. After reviewing
it, authorize the file:

```bash
direnv allow
```

`direnv` remembers the authorization until `.envrc` changes. It then loads the
development environment whenever you enter the repository and unloads it when
you leave. The initial load may take some time while Nix downloads or builds the
required packages.

The environment also creates a `tmux` session named `small-data-cluster` with
windows prepared for common development operations. A later section describes
the session and its commands.

If a secrets file for your system username does not exist, `.envrc` prints an
informational message similar to:

```text
-------------------------------
No secrets file for <username> at secrets/<username>.json
Create one from secrets/template.json and encrypt with sops.
You can use the 'create-secret' command to do that for you!
-------------------------------
```

The missing file does not prevent the development shell from loading. Until you
create it, impure evaluations do not receive a developer-specific configuration
through `SDC_SECRETS`.

## Create SOPS secrets

[SOPS](https://getsops.io/) is a tool for editing structured files whose values
are encrypted at rest. This project combines SOPS with
[age](https://github.com/FiloSottile/age), a file-encryption tool whose public
recipient keys can encrypt data and whose private identities decrypt it.

Developers should use a SOPS-encrypted JSON configuration instead of placing
real credentials in `config.toml`. The encrypted file can remain beside the
source and can be shared with explicitly configured recipients without exposing
its plaintext values. This reduces the risk of accidentally committing Tailscale
credentials, password hashes, or other deployment configuration in cleartext.

SOPS protects the configuration file at rest. It does not keep values encrypted
throughout the build. `.envrc` decrypts the file into `SDC_SECRETS`, and
`flake.nix` parses that value during impure evaluation. Evaluated values may
therefore appear in process environments, the Nix store, generated images, or
build output.

> **Security warning:** Treat the age private identity, authorized development
> shell, Nix store, generated images, and build workstation as sensitive. SOPS
> does not make secrets safe to print, log, pass to untrusted processes, or
> embed in publicly distributed images.

### Create an age identity

SOPS expects the developer's age identity at:

```text
~/.config/sops/age/keys.txt
```

If you do not already have an identity at that path, create one:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

The private identity in `keys.txt` begins with `AGE-SECRET-KEY-1`. Do not commit
it, copy it into the repository, or share it. Anyone who obtains the private
identity can decrypt files encrypted for its corresponding recipient.

Display the public recipient key when you need to add it to `.sops.yaml`:

```bash
age-keygen -y ~/.config/sops/age/keys.txt
```

The public recipient begins with `age1` and may be shared with other project
developers.

> **Advice:** Keep a secure backup of the private identity. An encrypted file
> cannot be recovered if every identity authorized to decrypt it is lost.

### Create the encrypted configuration

From the repository root, run:

```bash
create-secret
```

The command uses your system username and performs the following operations:

1. Copies `secrets/template.json` to `secrets/<username>.json`.
2. Encrypts the new file using the matching rule in `.sops.yaml`.
3. Opens the encrypted file with SOPS so that you can edit its plaintext view.
4. Requests a `direnv` reload after the editor closes.

Replace every template credential and example user value with configuration for
your development cluster. At minimum, verify the Tailscale configuration. Save
and close the editor; SOPS writes the encrypted representation to disk.

> **Caution:** Make at least one change before closing the SOPS editor. If
> creation fails or leaves a partial target file, correct the creation rule and
> run `create-secret --force` only after confirming that the partial file does
> not contain values you need.

If the target file already exists, `create-secret` refuses to replace it. The
`--force` option permits replacement:

```bash
create-secret --force
```

> **Warning:** `--force` overwrites the existing encrypted configuration with a
> new copy of the template before opening the editor. Preserve any values you
> still need before using this option.

The helper also supports `--user <username>`, but `.envrc` selects the current
system username. Use the override only when you want to create that file
explicitly.

> **Note:** If you use different system usernames on different development
> machines, create one canonical encrypted configuration and add a relative
> symbolic link for each additional username. For example, this repository uses
> `secrets/bentzin.json` as the encrypted file and `secrets/ture.json` as a
> symbolic link to it. Create the same arrangement from the repository root
> with:
>
> ```bash
> ln -s bentzin.json secrets/ture.json
> ```
>
> Replace `bentzin.json` with the existing encrypted filename and `ture.json`
> with the filename expected on the other machine. Use only the filename as the
> link target so that the relative link continues to resolve within `secrets/`
> when the repository is moved. Do not run the command if the destination
> already exists. `.envrc` follows the link and loads the same encrypted
> configuration for either system username.

### Edit and load the encrypted configuration

Edit an existing configuration through SOPS:

```bash
sops secrets/<username>.json
```

Use the secrets filename selected by `.envrc` in place of the example. SOPS
decrypts the values for the editor and encrypts them again when it writes the
file. If the edited content is not valid JSON, SOPS asks you to correct the
error or abort.

Because `.envrc` watches `secrets/`, saving the file causes `direnv` to reload.
You can request a reload explicitly when necessary:

```bash
direnv reload
```

During the reload, `.envrc` decrypts the selected file, compacts the JSON with
`jq`, and exports it as `SDC_SECRETS`. It also derives `TAILSCALE_APIKEY` and
`TAILSCALE_DOMAIN` for the development utility described earlier.

Do not manually decrypt the configuration into the repository or save a
plaintext copy beside it.
