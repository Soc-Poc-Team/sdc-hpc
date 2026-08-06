# Building Your Images

This section covers the available build outputs and the process of building
images for your `small-data-cluster`.

Images can be built before the cluster has been fully configured. The default
`config.toml` is sufficiently complete for Nix to evaluate the project and
produce the images. However, the resulting images do not contain a functional
deployment configuration and cannot be used to start an operational cluster.
Attempting to deploy them will result in failures during the boot or
service-startup process.

The project’s continuous integration pipeline intentionally uses the default
configuration to verify that the images and other project outputs can be built
successfully. A successful build therefore confirms that the source code
evaluates and compiles, but it does not confirm that the resulting cluster
configuration is deployable.

## Available Images and Packages

The build outputs of the `small-data-cluster` are exposed through the flake’s
Nix package outputs. They can therefore be built, inspected, or otherwise
processed using standard Nix commands.

An overview of the relevant Nix commands is available in the
[Nix command reference](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix).
This reference is particularly useful when modifying or developing the project.

The following package outputs are available for `x86_64-linux` systems:

| Package attribute                     | Description                                                                                                                |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `packages.x86_64-linux.default`       | Default package output. This is an alias for `packages.x86_64-linux.head`.                                                 |
| `packages.x86_64-linux.head`          | Builds the bootable ISO image for the headnode.                                                                            |
| `packages.x86_64-linux.worker`        | Builds the bootable ISO image for workernodes.                                                                             |
| `packages.x86_64-linux.headnode`      | Exposes the headnode system configuration for development purposes. It is not intended to be built directly as an image.   |
| `packages.x86_64-linux.workernode`    | Exposes the workernode system configuration for development purposes. It is not intended to be built directly as an image. |
| `packages.x86_64-linux.vm_headnode`   | Builds a QEMU virtual-machine image of the headnode for local development and testing.                                     |
| `packages.x86_64-linux.vm_workernode` | Builds a QEMU virtual-machine image of a workernode for local development and testing.                                     |
| `packages.x86_64-linux.devel`         | Contains additional development, documentation, monitoring, and cluster-management packages provided by the project.       |

### Development Packages

The `packages.x86_64-linux.devel` output contains the following additional
packages:

| Package      | Description                                                                         |
| ------------ | ----------------------------------------------------------------------------------- |
| `docs`       | Builds this project documentation.                                                  |
| `pharos`     | Internal utility that checks headnode availability and version compatibility.       |
| `sdc-hitman` | Internal utility used to terminate nodes within a cluster.                          |
| `slurm`      | The project’s customized build of Slurm.                                            |
| `sne`        | The project’s build of `slurm-node-exporter`, used to expose Slurm-related metrics. |

The `head` and `worker` outputs are the primary packages required for physical
deployment. The `vm_headnode` and `vm_workernode` outputs are intended for
testing changes without immediately writing images to physical USB drives.
