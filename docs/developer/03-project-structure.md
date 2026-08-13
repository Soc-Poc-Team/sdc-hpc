# Project structure

This chapter explains where the main parts of the project are located and how
the repository is organized. Use it as a map when tracing an existing feature or
deciding where to implement a change.

The project separates shared NixOS configuration, role-specific behavior,
project packages, development tools, and documentation. Most features cross more
than one of these boundaries. For example, a service may have a package in
`packages/`, a NixOS module in `common/` or `roles/`, a flake output in
`flake.nix`, and operational instructions in `docs/`.

## Root files

Files in the repository root define the project, its deployment configuration,
and its main development interfaces.

**TODO:** What files do we have here and what why

### Flake definition

`flake.nix` is the primary project entry point. It declares external inputs and
constructs the following outputs:

- Headnode and worker NixOS configurations.
- Physical ISO images and QEMU development virtual machines.
- The default and documentation development shells.
- Project packages and applications.
- The repository formatter.

The helper function `mkBase` combines the shared configuration in `common/` with
one role from `roles/`. It also passes `userConfig`, the flake, and other
required values to the module system.

`flake.lock` records the exact revisions and hashes of the flake inputs. Review
changes to this file together with the corresponding input changes in
`flake.nix`.

**TODO:** Flake reference - A non nix user might not understand it otherwise

### Deployment configuration

`config.toml` contains the unencrypted configuration schema and example values.
`flake.nix` reads this file during pure evaluation. During impure evaluation,
the `SDC_SECRETS` environment variable can replace it with JSON loaded from a
SOPS-encrypted developer configuration.

`VERSION` contains the current cluster compatibility version followed by any
additional worker versions accepted by the headnode. Pharos uses this file to
prevent an incompatible worker from joining the cluster.

### Build and formatting entry points

`build-batch.sh` builds the standard physical and virtual targets and creates
links under `results/`. `treefmt.nix` configures the formatters and static
checks run through `nix fmt`.

The `.envrc` file loads the impure development shell, decrypts the current
developer's SOPS configuration when present, exports development variables, and
prepares the project `tmux` session.

## Shared NixOS configuration

The `common/` directory contains modules imported by both the headnode and every
worker node. A change in this directory must be evaluated for both roles.

### Shared system configuration

`common/default.nix` is the root shared module. It imports the common services
and cluster targets and defines system-wide behavior such as:

- Declarative user accounts and groups.
- Common packages and shell configuration.
- SSH, firewall, and network defaults.
- The shared Munge key used by Slurm.
- The Jupyter kernel dependency.

`common/iso-image.nix` applies settings shared by the live images, including the
minimal installation image profile and the disabled TPM2 integration.

### Cluster targets

`common/targets/cluster.nix` defines `pre-cluster.target` and `cluster.target`.
These targets form the startup contract for services across both roles.

When adding a cluster service, decide explicitly whether it is a prerequisite
for cluster readiness, a service started as part of the cluster, or a service
that starts only after the cluster is ready.

### Shared services

`common/services/` contains services used by both node roles:

| Path                 | Responsibility                                      |
| -------------------- | --------------------------------------------------- |
| `avahi.nix`          | Multicast DNS publication and name resolution.      |
| `custom/munge.nix`   | Project-specific Munge module and daemon.           |
| `dask/`              | Dask scheduler and worker NixOS modules.            |
| `slurm.nix`          | Shared Slurm configuration and dynamic node daemon. |
| `tailscale.nix`      | Tailscale daemon and automatic node enrollment.     |
| `tailscale-tidy.nix` | Removal of an existing same-hostname device record. |

The modules commonly expose NixOS options and enable different implementations
according to the current role. For example, the shared Slurm module enables the
controller only when the configured hostname is `headnode`, but starts a dynamic
`slurmd` on every node.

### Shared environments

`common/environments/jlabkernels.nix` defines the project-specific Jupyter
kernel and its Python packages. The resulting kernel is included as a system
dependency so that a Slurm-launched Jupyter server can use the same environment
on any node.

## Node roles

The `roles/` directory composes the behavior that differs between the headnode
and worker nodes. Each role has one top-level configuration and a set of
role-specific services.

### Headnode role

`roles/headnode/headnode-configuration.nix` is the headnode entry point. It sets
the fixed `headnode` hostname, enables the Dask scheduler, imports the central
services, and configures the bootable image. It also provides the experimental
`persist-to-disk` command.

The services below `roles/headnode/services/` provide:

- The web dashboard through Nginx.
- Grafana, Prometheus, Loki, Alloy, and Slurm metrics.
- JupyterHub and its Slurm-backed notebook profiles.
- The NFS export for shared user homes.
- Headnode-specific Slurm controller ordering.
- Pharos version compatibility checks.
- Optional telemetry.

`roles/headnode/modules/` contains packages or modules used only by headnode
services. This currently includes the Slurm node exporter and local WrapSpawner
packaging.

### Worker role

`roles/workernode/workernode-configuration.nix` is the worker entry point. It
enables DHCP, selects the worker hostname behavior, enables the Dask worker, and
imports the worker services.

The services below `roles/workernode/services/` provide:

- A Pharos-based wait for a compatible headnode.
- The NFS mount for `/homes`.
- Node Exporter metrics and Alloy log forwarding.
- Optional journal output on `tty1`.
- A hostname derived from a network-interface address.

Worker services must account for the headnode being unavailable during startup.
Their ordering usually involves `awaitHeadnode.service`, `pre-cluster.target`,
or both.

## Project packages

The `packages/` directory contains software built or wrapped specifically for
the `small-data-cluster`. Packages are exposed through the `devel` package set
in `flake.nix` when they are useful outside their consuming NixOS module.

### Pharos

`packages/pharos/` contains a small C++ client and server. The server reads the
compatible versions from `VERSION`. A worker runs the client before joining and
interprets its exit status as compatible, incompatible, incorrectly invoked, or
temporarily unreachable.

### Cluster shutdown utility

`packages/sdc-hitman/` packages the `sdc-hitman` shell application. The utility
drains selected Slurm nodes, optionally waits for allocations, updates or
removes their scheduler records, and shuts them down over SSH.

### Secret creation helper

`packages/create-secret.nix` defines the `create-secret` command available in
the default development shell. It creates a developer-specific configuration
from `secrets/template.json`, configures a SOPS recipient, encrypts the file,
and opens it for editing.

## Development tooling

The `dev/` directory contains local tools that support building, testing, and
deploying development images. These tools are not services installed on every
cluster node.

| Path                   | Purpose                                                   |
| ---------------------- | --------------------------------------------------------- |
| `setup-tmux.sh`        | Prepares windows for builds, virtual machines, and flash. |
| `vm_launcher.sh`       | Starts profile-based QEMU instances from ISO images.      |
| `flash.sh`             | Writes the worker ISO to authorized USB devices.          |
| `tailscale-tidy.py`    | Lists or deletes development-tailnet device records.      |
| `.write_authorization` | Lists USB device identifiers accepted by `flash.sh`.      |

Some development tools can modify external state or storage devices. Review
their configured paths, selected tailnet, and target devices before running
them.

## Secrets

The `secrets/` directory contains the JSON configuration template and encrypted
developer configurations. `.sops.yaml` in the repository root maps filenames to
the age recipients allowed to decrypt them.

`.envrc` selects `secrets/<username>.json`, decrypts it with SOPS, and exports
the compact JSON as `SDC_SECRETS`. A relative symbolic link can map several
system usernames to one canonical encrypted file.

Do not treat an encrypted source file as proof that secrets remain encrypted in
the development environment or build outputs. Impure evaluation exposes the
decrypted configuration to Nix, and the resulting values may enter the Nix store
and generated images.

## Documentation

The `docs/` directory contains Markdown sources, shared assets, and the Nix
implementation of the PDF rendering environment.

The administration and developer manuals are separate documentation sets under
`docs/admin/` and `docs/developer/`. Files within each set are concatenated in
filename order. Each set contains a `metadata.yaml` file for its title-page and
PDF metadata.

The shared documentation files have the following roles:

- `style.md` defines the writing and formatting requirements.
- `defaults.yaml` configures Pandoc and LuaLaTeX.
- `header.tex` defines shared PDF styling.
- `docsshell.nix` provides the documentation tools.
- `render-docs.nix` defines the `render-docs` command.
- `default.nix` builds all documentation sets as a Nix package.

## Automation and repository integration

The repository contains automation for formatting and image builds in several
locations.

### Continuous integration

`.gitlab-ci.yml` and `.github/workflows/` define continuous integration builds.
Review both systems when changing build attributes, output paths, or image
names. A successful CI image build verifies that the default configuration can
be evaluated and built; it does not prove that its placeholder credentials form
a deployable cluster.

### Git hooks

`.githooks/` contains the project-managed Git hooks and their installer. The
pre-commit hook runs `nix fmt -- --fail-on-change`. Installing the hooks changes
the local `.git/hooks` directory and is therefore an explicit developer action.

## Decide where a change belongs

Use the narrowest location that matches the change:

- Put behavior required by both roles in `common/`.
- Put role-specific system behavior in the corresponding directory under
  `roles/`.
- Put independently built project software in `packages/`.
- Put workstation-only helpers in `dev/`.
- Define or expose top-level build interfaces in `flake.nix`.
- Document administrator-visible behavior in `docs/admin/` and implementation or
  contributor workflows in `docs/developer/`.

When a change crosses these boundaries, update every affected layer and test the
complete path from evaluation to runtime behavior.
