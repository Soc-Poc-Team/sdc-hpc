# Developer tools

This chapter describes the tools provided by the `small-data-cluster` repository
and its development environments. Use the default _development shell_ for
source, configuration, image, and local CI work. Use the _documentation shell_
when you need the complete PDF-rendering toolchain.

Some tools create images, virtual machines, tailnet records, Git-hook links, or
bootable USB drives. Read the relevant warnings before using them.

## Enter a development environment

The project defines two development shells. `direnv` normally loads the default
shell automatically after you authorize `.envrc`. You can also enter either
shell manually from the repository root.

Enter the default shell for ordinary development:

```bash
nix develop
```

Enter the documentation shell for PDF rendering:

```bash
nix develop .#docsshell --impure
```

The default shell provides these important tools:

| Tool              | Purpose                                                      |
| ----------------- | ------------------------------------------------------------ |
| `qemu`            | Running the Nix-generated development virtual machines.      |
| `neovim`          | Editing source and configuration files.                      |
| `alejandra`       | Formatting Nix expressions.                                  |
| `mkpasswd`        | Generating password hashes for test configuration.           |
| `sops`, `age`     | Editing encrypted configuration and managing age identities. |
| `gitlab-ci-local` | Running selected GitLab CI jobs locally.                     |
| `jq`              | Inspecting and transforming JSON.                            |
| `create-secret`   | Creating a developer-specific encrypted configuration.       |
| `render-docs`     | Rendering the administration or developer manual as a PDF.   |

The documentation shell additionally supplies Pandoc, LuaLaTeX, Graphviz,
Mermaid, ImageMagick, Ghostscript, Poppler, and supporting fonts. These tools
are available for documentation rendering and asset generation; they are not
part of the normal cluster runtime.

> **Note:** The default shell does not install `direnv` or `tmux`. Install and
> connect `direnv` to your shell as described in
> [Getting started](#getting-started), and install `tmux` on the workstation
> before using the prepared session. TODO: See
> https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/215
> for details on this.

## Format and check the repository

Run the flake formatter before committing a change:

```bash
nix fmt
```

The formatter uses the configuration in `treefmt.nix`. It formats Nix, shell,
Markdown, YAML, and other supported source files, and it runs static checks such
as `deadnix`, `shellcheck`, and `mdsh` where applicable.

To check whether formatting would change the repository without modifying it,
run:

```bash
nix fmt -- --fail-on-change
```

The project-managed pre-commit hook runs this same check. Install the hook from
the repository root:

```bash
./.githooks/install-hooks.sh
```

The installer creates symbolic links under `.git/hooks` and asks before
replacing an existing hook with the same name.

## Build images and virtual machines

The flake exposes iso images and local QEMU virtual-machine launchers for these
on the `x86_64-linux` platform.

| Command                     | Result                                      |
| --------------------------- | ------------------------------------------- |
| `nix build .#head`          | Headnode ISO under `result/iso/`.           |
| `nix build .#worker`        | Worker ISO under `result/iso/`.             |
| `nix build .#vm_headnode`   | Headnode QEMU launcher under `result/bin/`. |
| `nix build .#vm_workernode` | Worker QEMU launcher under `result/bin/`.   |

### Build the standard set

Use `build-batch.sh` to build the worker ISO, worker virtual machine, headnode
ISO, and headnode virtual machine in that order:

```bash
./build-batch.sh
```

The script creates result links under `results/` instead of using the default
`result` link. When a developer-specific SOPS configuration must replace
`config.toml`, use impure evaluation:

```bash
./build-batch.sh --impure
```

The script passes these Nix options through to every build target:

| Option            | Effect                                                         |
| ----------------- | -------------------------------------------------------------- |
| `--rebuild`       | Rebuilds outputs instead of relying only on valid substitutes. |
| `--rebuild-check` | Rebuilds outputs and compares them with existing outputs.      |
| `--repair`        | Attempts to repair damaged or missing Nix store paths.         |
| `--verbose`       | Prints executed shell commands.                                |

Use `--clean` to remove the `results/` links:

```bash
./build-batch.sh --clean
```

> **Caution:** `--clean` removes the complete `results/` directory. The script
> detects QEMU processes that appear to use that directory and offers to stop
> them, but it cannot guarantee that every consumer has stopped. It removes
> result links only; it does not remove Nix store outputs. Iterative devlopment
> on the `small-data-cluster` likely causes a lot of unused paths in the nix
> store! You can clear unused items from the nix store.

### Run the generated virtual machines

Run required virtual-machine target.

```bash
nix run .#vm_headnode

nix run .#vm_workernode
```

`build-batch.sh` creates equivalent launchers under `results/`:

```bash
./results/vm_headnode/bin/run-headnode-vm
./results/vm_workernode/bin/run-unnamed-vm
```

The headnode virtual machine forwards host TCP port `2222` to guest SSH port
`22`. It uses 8 GiB of memory and six virtual CPU cores. The worker virtual
machine uses 4 GiB of memory and six virtual CPU cores. _Adjust the flake rather
than editing generated launchers when these defaults are unsuitable._

### Use the profile-based VM launcher

`dev/vm_launcher.sh` is a separate, profile-based QEMU launcher. It searches for
ISO files below `.vml/images/` and profiles below `.vml/profiles/`.

List the available images and profiles:

```bash
./dev/vm_launcher.sh list
```

Start an image with a profile:

```bash
./dev/vm_launcher.sh <image> <profile>
```

Replace `<image>` with an ISO filename without the `.iso` suffix and `<profile>`
with a profile filename without the `.conf` suffix. The script creates a qcow2
overlay under `.vml/runtime/overlays/`, starts QEMU in the background, and
prints the assigned SSH and VNC ports.

### Provide images and profiles

Place an ISO and its profile in the following layout:

```text
.vml/
├── images/
│   └── development-headnode.iso
└── profiles/
    └── development.conf
```

For this layout, start the virtual machine with:

```bash
./dev/vm_launcher.sh development-headnode development
```

The profile is a line-oriented `KEY=VALUE` file. Empty lines and lines beginning
with `#` are ignored. The following example uses every supported setting:

```ini
# QEMU virtual-machine profile
DISK_SIZE=20G
MEMORY=4096
CORES=4
CPU=host
EXTRA=-nographic
```

| Setting     | Default | Meaning                                            |
| ----------- | ------- | -------------------------------------------------- |
| `DISK_SIZE` | `20G`   | Size of the new qcow2 overlay disk.                |
| `MEMORY`    | `2048`  | Guest memory in MiB, passed to QEMU's `-m` option. |
| `CORES`     | `2`     | Guest virtual CPU cores, passed to `-smp`.         |
| `CPU`       | `host`  | QEMU CPU model, passed to `-cpu`.                  |
| `EXTRA`     | Empty   | One additional argument passed unchanged to QEMU.  |

`EXTRA=-nographic` is useful for a terminal-only virtual machine. The launcher
passes `EXTRA` as one argument. Do not use it for a multi-argument QEMU option,
such as `-device <value>`, because the script does not split that value into
separate arguments.

The script creates a unique qcow2 overlay for every invocation and does not
modify the source ISO. It selects an unused host SSH port from `2200` through
`7199` and a VNC display number from `1` through `99`. Record the printed values
before connecting to the virtual machine or opening the VNC display.

You can override the default directories without modifying the script:

```bash
IMAGES_ROOT=<images-directory> \
PROFILES_ROOT=<profiles-directory> \
RUNTIME_ROOT=<runtime-directory> \
./dev/vm_launcher.sh development-headnode development
```

Replace each placeholder with an existing directory. This is useful for testing
an image outside the repository or keeping large VM artifacts on another
filesystem.

> **Note:** The repository does not provide a default ISO or profile for this
> launcher. It requires a bootable ISO and a matching profile created or copied
> by the developer.

## Use the prepared tmux session

`dev/setup-tmux.sh` creates a `small-data-cluster` session with these windows:

| Window        | Prepared work                                            |
| ------------- | -------------------------------------------------------- |
| `vms`         | QEMU commands for the generated worker and headnode VMs. |
| `flash`       | The worker USB flash command from the `dev/` directory.  |
| `batch-build` | An impure build of the standard image and VM set.        |

When `.envrc` loads, it calls the script with `-n` and leaves an existing
session unchanged. Create or recreate a session manually from the repository
root:

```bash
./dev/setup-tmux.sh
```

The command asks before replacing an existing session. To recreate the session
without a prompt, use:

```bash
./dev/setup-tmux.sh -y
```

Attach to the session with:

```bash
tmux attach -t small-data-cluster
```

> **Warning:** Recreating the session stops the existing `tmux` server. Commands
> running in its panes, including virtual machines or image builds, are
> terminated.

## Manage development secrets

The `create-secret` command copies `secrets/template.json` into a
developer-specific file, encrypts it with SOPS, opens it for editing, and asks
`direnv` to reload afterward.

Create the file selected for the current system username:

```bash
create-secret
```

Use another filename only when you intend to manage it explicitly:

```bash
create-secret --user <username>
```

The command refuses to overwrite an existing file. Use `--force` only after
backing up any required values:

```bash
create-secret --force
```

The [Getting started](#getting-started) chapter explains age identities,
creation rules, symlinked developer configurations, and the security boundary of
decrypted values.

## Manage development tailnet devices

`dev/tailscale-tidy.py` lists and deletes devices through the Tailscale API. It
requires `TAILSCALE_APIKEY` and `TAILSCALE_DOMAIN`, which `.envrc` exports from
the selected encrypted configuration.

List the devices in the selected tailnet:

```bash
./dev/tailscale-tidy.py list
```

Delete one device record by its exact hostname:

```bash
./dev/tailscale-tidy.py delete <hostname>
```

Replace `<hostname>` with a value printed by `list`.

> **Warning:** `delete` sends a Tailscale API request immediately and does not
> request confirmation. Confirm the active `TAILSCALE_DOMAIN` and hostname
> before running it.

> **Documentation limitation:** The script imports the Python `requests`
> package, but the default development shell does not currently provide it. See
> https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/216
> for more information on progress about this.

## Write worker images to USB drives

`dev/flash.sh` writes the built worker ISO to every connected USB drive listed
in `dev/.write_authorization`. Each line in the authorization file is a filename
from `/dev/disk/by-id/` without the directory prefix.

Run a dry run from the `dev/` directory:

```bash
cd dev
./flash.sh --dry
```

The dry run prints the `dd` command that the script would use for each currently
connected and authorized drive. Verify the device identifiers, model, capacity,
and intended ISO before writing.

Write the worker ISO after the dry run is correct:

```bash
./flash.sh
```

> **Warning:** The flash command overwrites every connected, authorized USB
> drive completely. It runs writes concurrently. Confirm that the authorization
> file contains only dedicated target drives, unmount their partitions first,
> and do not disconnect a drive while writing.

The flash tool does not write the headnode ISO. Use a separate, reviewed `dd`
command for that image as described in the administration manual.

## Render documentation

The `render-docs` command renders one or more documentation sets with Pandoc and
LuaLaTeX. Enter the documentation shell first when the required renderer tools
are not already available.

Render the complete documentation set:

```bash
render-docs
```

Render only the developer manual:

```bash
render-docs developer
```

By default, the command writes PDFs to `docs/`. Use a temporary output directory
when previewing changes:

```bash
OUTPUT_ROOT=/tmp/sdc-doc-preview DOCS_ROOT=docs render-docs developer
```

Review Pandoc and LaTeX messages, then inspect the generated PDF. A successful
renderer exit does not prove that tables, code blocks, page breaks, and links
are visually correct.

## Run selected GitLab CI jobs locally

`gitlab-ci-local` can run selected jobs from `.gitlab-ci.yml` on the development
workstation. First list the available jobs:

```bash
gitlab-ci-local --list
```

Then run one job by name:

```bash
gitlab-ci-local <job-name>
```

Replace `<job-name>` with a job shown by the list command. Local CI execution
does not exactly reproduce GitLab runners, their credentials, or their external
services. Use it to shorten feedback cycles, then verify changes in the
project's configured continuous-integration pipeline.

## Use runtime utilities during integration tests

Some project tools are installed in the cluster images instead of the default
development shell. They are useful when testing a complete deployment but are
not ordinary workstation development commands.

| Tool              | Available on              | Purpose                                    |
| ----------------- | ------------------------- | ------------------------------------------ |
| `sdc-hitman`      | Headnode and worker nodes | Drains, stops, and removes Slurm nodes.    |
| `persist-to-disk` | Headnode                  | Invokes `disko-install` for a target disk. |
| `pharos`          | Worker nodes              | Checks headnode compatibility at startup.  |
| `pharosd`         | Headnode                  | Serves worker compatibility checks.        |

> **Warning:** `sdc-hitman` stops nodes over SSH, and `persist-to-disk` erases
> its target disk. Do not use either command on a shared or production-like
> deployment without confirming the targets and expected consequences.

> **Important:** `persist-to-disk` is inherited from an earlier project version.
> It is currently unmaintained and has not been tested with recent
> `small-data-cluster` versions. Do not rely on it for a deployment until you
> have reviewed, updated, and tested its installation path.
