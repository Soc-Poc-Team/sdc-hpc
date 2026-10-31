# Introduction

This manual describes how to develop and maintain the `small-data-cluster`.

If you are reading this, it probably means that the `small-data-cluster` will
receive further development, updates, or maintenance and may eventually be put
into operation. I am very happy that you are interested in continuing the
project, and I hope that this documentation helps you navigate both the project
and its development.

The `small-data-cluster` is an experimental research project under active
development. Interfaces, configuration options, and implementation details may
change between revisions. Before changing the project, review the current source
and do not rely on this manual as a substitute for the implementation.

Please also update this manual and the other project documentation when you make
changes to the project.

This chapter provides a basic overview of the project. The following chapters
describe specific services, features, and tools in more detail.

> **Note:** If required because you hit the limits of this documentation and
> cant find information you really need, you can try to contact me, including
> after I have left the BigDataLab, through my alumni email at
> `ture.bentzin@alumni.fh-aachen.de`.

## Project purpose

The project provides an on-demand computing cluster for small and medium-sized
enterprises. It builds bootable NixOS images for commercial off-the-shelf
`x86_64` hardware. An organization can boot otherwise independent machines as
one temporary cluster without installing the cluster operating system on their
internal drives.

A deployment contains one headnode and zero to more worker nodes. The headnode
coordinates the cluster and provides its central services. Worker nodes add
compute capacity after joining the headnode. Both roles use the same project
revision and deployment configuration.

The standard images are live systems. Runtime state, including the shared
`/homes` directory, is stored in memory and is lost when the headnode stops.
Although the repository contains an experimental `persist-to-disk` path for the
headnode, developers must not assume that a deployment provides persistent
storage or backups.

## Architectural overview

The root `flake.nix` reads the deployment configuration and constructs the
headnode and worker NixOS systems. Both roles inherit the modules in `common/`.
Role-specific modules then add the services and behavior required by the
headnode or worker nodes.

The shared system provides the following foundations:

- Users and a common `/homes/<username>` home-directory layout.
- Tailscale enrollment and name-based communication between nodes.
- Slurm controller or worker behavior, depending on the node role.
- Munge authentication for Slurm.
- Dask services.
- SSH access, common packages, and the cluster systemd targets.

The headnode adds the central services:

- The Slurm controller and dynamic node registration.
- JupyterHub with Slurm-backed notebook servers.
- The NFS export for `/homes`.
- Grafana, Prometheus, Loki, Alloy, and their exporters.
- The web dashboard and the Pharos compatibility service.
- Optional telemetry.

A worker node waits for a compatible headnode, mounts the headnode's `/homes`
export, registers itself dynamically with Slurm, starts a Dask worker, and
exports metrics and logs. By default, its hostname begins with `worker-` and is
derived from a detected network-interface address.

### Service startup contract

Cluster services use two systemd targets defined in
`common/targets/cluster.nix`:

- `pre-cluster.target` represents the prerequisites for cluster communication.
  It requires the automatic Tailscale connection and waits for time
  synchronization.
- `cluster.target` represents a running `small-data-cluster`. Cluster services
  are ordered around or required by this target.

Worker nodes can add another prerequisite through `awaitHeadnode.service`. This
service contacts the headnode's Pharos server and checks the version in
`VERSION`. A worker does not proceed when the headnode rejects its version or
when the configured timeout expires.

When adding a service, define its relationship to these targets explicitly.
Starting a daemon successfully is not sufficient if it starts before its
network, storage, authentication, or headnode dependencies are ready.

## Declarative deployment model

The project treats the generated images as the deployment unit. User accounts,
credentials, service configuration, packages, and most runtime behavior are
defined before the images are built. Administrators apply a change by rebuilding
and reflashing the affected images rather than by modifying running nodes.

The repository supports two configuration sources:

- `config.toml` provides the pure, unencrypted configuration used by default.
- The `SDC_SECRETS` environment variable can provide a decrypted JSON
  configuration during an impure evaluation. The development environment obtains
  this value from a SOPS-encrypted file under `secrets/`.

`flake.nix` exposes the selected value as `userConfig` and passes it to the
NixOS modules through `specialArgs` and module arguments. Configuration values
can therefore affect evaluation and may be copied into the Nix store or an
image. Encryption of the source file does not prevent evaluated secrets from
appearing in build outputs.

> **Security warning:** The current configuration includes Tailscale
> credentials, password hashes, and potentially a Grafana administrator password
> in evaluated Nix data. Treat the build machine, Nix store, result images,
> secret environment, and flashed media as sensitive. Never add real credentials
> to tests, examples, documentation, or committed configuration.

All images in one deployment should be produced from a compatible project
revision and the same configuration. Changes to shared users, numeric user IDs,
network credentials, authentication material, or service protocols generally
require rebuilding and replacing every node image.

## Repository layout

The main source directories have the following responsibilities:

| Path        | Responsibility                                                     |
| ----------- | ------------------------------------------------------------------ |
| `common/`   | Shared NixOS modules, services, environments, and systemd targets. |
| `roles/`    | Headnode and worker role composition and role-specific services.   |
| `packages/` | Project packages and utilities, including Pharos and `sdc-hitman`. |
| `dev/`      | Local development, virtual-machine, and USB-flashing helpers.      |
| `docs/`     | Documentation sources, rendering configuration, and shared assets. |
| `secrets/`  | SOPS templates and encrypted developer configurations.             |

Files in the repository root define the flake, deployment template, formatter,
development environment, build automation, and continuous integration jobs. The
most important entry points are:

- `flake.nix` for inputs, NixOS construction, packages, applications, and
  development shells.
- `config.toml` for the unencrypted configuration schema and example values.
- `build-batch.sh` for building the physical and virtual image set.
- `treefmt.nix` for the repository formatters and static checks.
- `VERSION` for worker-to-headnode compatibility.

## Flake outputs

The flake currently targets `x86_64-linux`. Its principal outputs are:

| Output                                | Purpose                                     |
| ------------------------------------- | ------------------------------------------- |
| `packages.x86_64-linux.head`          | Bootable headnode ISO.                      |
| `packages.x86_64-linux.worker`        | Bootable worker ISO.                        |
| `packages.x86_64-linux.vm_headnode`   | QEMU headnode launcher for development.     |
| `packages.x86_64-linux.vm_workernode` | QEMU worker launcher for development.       |
| `nixosConfigurations.headnode`        | Installable headnode NixOS configuration.   |
| `nixosConfigurations.workernode`      | Worker NixOS configuration.                 |
| `devShells.x86_64-linux.default`      | Main project development environment.       |
| `devShells.x86_64-linux.docsshell`    | Documentation rendering environment.        |
| `packages.x86_64-linux.devel`         | Project utilities and development packages. |

The default package is the headnode ISO. The `headnode` and `workernode` package
attributes inside `packages.x86_64-linux` are intermediate system configurations
used to construct other outputs; they are not the physical ISO outputs.
