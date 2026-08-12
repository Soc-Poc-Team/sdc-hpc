# Build the images

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

## Available images and packages

The build outputs of the `small-data-cluster` are exposed through the flake’s
Nix package outputs. They can therefore be built, inspected, or otherwise
processed using standard Nix commands.

An overview of the relevant Nix commands is available in the
[Nix command reference](https://nix.dev/manual/nix/2.18/command-ref/new-cli/nix).
This reference is particularly useful when modifying or developing the project.

The following package outputs are available for `x86_64-linux` systems:

| Package attribute                     | Description                                                                                                                 |
| ------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `packages.x86_64-linux.default`       | Default package output. This is an alias for `packages.x86_64-linux.head`.                                                  |
| `packages.x86_64-linux.head`          | Builds the bootable ISO image for the headnode.                                                                             |
| `packages.x86_64-linux.worker`        | Builds the bootable ISO image for worker nodes.                                                                             |
| `packages.x86_64-linux.headnode`      | Exposes the headnode system configuration for development purposes. It is not intended to be built directly as an image.    |
| `packages.x86_64-linux.workernode`    | Exposes the worker node system configuration for development purposes. It is not intended to be built directly as an image. |
| `packages.x86_64-linux.vm_headnode`   | Builds a QEMU virtual-machine image of the headnode for local development and testing.                                      |
| `packages.x86_64-linux.vm_workernode` | Builds a QEMU virtual-machine image of a worker node for local development and testing.                                     |
| `packages.x86_64-linux.devel`         | Contains additional development, documentation, monitoring, and cluster-management packages provided by the project.        |

### Development packages

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

## The `build-batch` utility

The `small-data-cluster` includes a script named `build-batch.sh`, which is the
recommended method for building the deployment and virtual-machine images. The
script builds all standard image targets in sequence and creates convenient
result links inside the repository’s `results/` directory.

When `direnv` loads the project environment, it normally creates a `tmux`
session named `small-data-cluster`. This session contains prepared windows for
building images, running virtual machines, and flashing USB drives.

### Set up the `tmux` session

The [tmux](https://github.com/tmux/tmux/wiki) session is normally created
automatically when the project’s `direnv` environment is loaded. When `direnv`
is not being used, or when you need to recreate the session manually, run the
following command from the repository root:

```bash
./dev/setup-tmux.sh
```

If a session named `small-data-cluster` already exists, the script asks whether
it should be recreated. Recreating the session terminates the existing session
and any shell processes running inside it.

The following options control this behavior:

| Option | Description                                                                         |
| ------ | ----------------------------------------------------------------------------------- |
| `-y`   | Recreates an existing `small-data-cluster` session without asking for confirmation. |
| `-n`   | Keeps an existing session and exits without asking for confirmation.                |

For example, to recreate the session automatically:

```bash
./dev/setup-tmux.sh -y
```

> **Warning:** Recreating the session closes all running shells and commands
> inside the existing session. Ensure that no build, flashing, or development
> process is still required before using `-y`.

### Open the `tmux` session

Attach to the prepared session by running:

```bash
tmux attach-session -t small-data-cluster
```

The session contains the following windows:

| Window        | Description                                                                      |
| ------------- | -------------------------------------------------------------------------------- |
| `vms`         | Contains two panes prepared for starting a virtualized worker node and headnode. |
| `flash`       | Opens the `dev/` directory and prepares the flash-tool command.                  |
| `batch-build` | Prepares the recommended command for building all standard images.               |

The commands in these windows are generally inserted into the shell but are not
executed automatically. For the first execution, press **Enter** when you are
ready to run the command. Later, you can use your shell history to restore the
previous command, usually by pressing the up arrow at the shell prompt, and run
it again.

Common `tmux` navigation shortcuts include:

| Shortcut                    | Action                                          |
| --------------------------- | ----------------------------------------------- |
| `Ctrl-b`, then `n`          | Move to the next window.                        |
| `Ctrl-b`, then `p`          | Move to the previous window.                    |
| `Ctrl-b`, then a number     | Open the window with the corresponding number.  |
| `Ctrl-b`, then an arrow key | Move between panes.                             |
| `Ctrl-b`, then `d`          | Detach from the session without terminating it. |

Detaching from the session leaves running builds and virtual machines active.
You can reconnect later using the same `tmux attach-session` (short: `tmux a`)
command.

### Build the images

Open the `batch-build` window. The following command should already be prepared:

```bash
./build-batch.sh --impure
```

The `--impure` option is required when the build must access decrypted secrets
or other configuration values provided outside the flake’s declared inputs. When
using only the unencrypted configuration (`config.toml`) in the repository, a
pure build can be performed by omitting this option. This purity flag controls
which configuration backend is used.

Press **Enter** to start the build. It may take some time to finish, depending
on your network connection and the build machine’s hardware.

The script builds the following targets in order:

1. `worker`
2. `vm_workernode`
3. `head`
4. `vm_headnode`

The generated result links are placed under:

```text
results/
├── worker
├── vm_workernode
├── head
└── vm_headnode
```

The physical deployment images can be found through the `worker` and `head`
result links. The `vm_workernode` and `vm_headnode` outputs contain launch
scripts for local QEMU-based testing.

The script stops immediately when one of the builds fails. Targets appearing
later in the sequence will not be built until the error has been resolved and
the command is run again.

After all four targets have been built successfully, the generated physical and
virtual images are ready for testing or deployment.

### `build-batch.sh` command reference

The general command syntax is:

```bash
./build-batch.sh [OPTIONS]
```

The following options are supported:

| Option            | Description                                                                                                                              |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `--impure`        | Permits impure Nix evaluation and passes `--impure` to every build. This is normally required when using decrypted secret configuration. |
| `--clean`         | Removes the complete `results/` directory instead of building images.                                                                    |
| `--verbose`       | Enables Bash command tracing and prints commands as the script executes them.                                                            |
| `--rebuild`       | Passes the Nix `--rebuild` option to every build.                                                                                        |
| `--rebuild-check` | Passes the Nix `--rebuild-check` option to every build.                                                                                  |
| `--repair`        | Passes the Nix `--repair` option to every build.                                                                                         |

Options beginning with `--` that are not included in this list are not forwarded
to Nix. The script does not provide an option for building only one of the four
targets because headnode and worker images from different builds must not be
used together.

#### Impure builds

When `--impure` is supplied, the script prints the following notice before
starting:

```text
Building impure results!
```

An impure build can access values outside the flake’s explicitly declared
inputs. In the `small-data-cluster`, this is used to make decrypted
configuration secrets available during evaluation by reading an environment
variable called `SDC_SECRETS`.

#### Clean build results

To remove all result links created by the script, run:

```bash
./build-batch.sh --clean
```

The cleanup operation deletes the entire `results/` directory and then exits
without building any images.

Before deleting the directory, the script checks whether a running QEMU process
appears to reference it. This can occur when one of the development virtual
machines is still running. When such a process is detected, the script offers
the following choices:

| Choice | Action                                                                      |
| ------ | --------------------------------------------------------------------------- |
| `a`    | Continue deleting the result links without stopping the detected processes. |
| `b`    | Terminate the detected QEMU processes and then continue with cleanup.       |
| `c`    | Abort without deleting the directory.                                       |

Prefer stopping virtual machines normally before cleaning the build results.
Terminating QEMU processes may cause unsaved state inside the virtual machines
to be lost.

> **Note:** Deleting the `results/` directory removes the result links but does
> not remove the corresponding build outputs from the Nix store. It only cleans
> the result links from your working directory.

#### Rebuild outputs

The `--rebuild` option instructs Nix to rebuild the requested outputs instead of
relying exclusively on existing valid build results:

```bash
./build-batch.sh --impure --rebuild
```

The `--rebuild-check` option rebuilds outputs and checks whether the new results
match the existing results:

```bash
./build-batch.sh --impure --rebuild-check
```

This can help identify non-reproducible builds and is usually only important for
developers.

The `--repair` option asks Nix to repair damaged or missing store paths when
possible:

```bash
./build-batch.sh --impure --repair
```

These options are primarily useful for development, troubleshooting, and
reproducibility testing. A normal deployment build generally requires only:

```bash
./build-batch.sh --impure
```

or

```bash
./build-batch.sh
```
