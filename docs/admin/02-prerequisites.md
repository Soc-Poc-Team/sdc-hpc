# Prerequisites

We have streamlined the deployment of a `small-data-cluster` as much as
possible. However, several prerequisites must still be met. Work through this
section before beginning the deployment of a cluster.

## Nix-enabled build machine

The `small-data-cluster` is a Nix and NixOS-based project. Therefore, a machine
capable of executing Nix builds is required.

You can learn more about Nix and Nixos here at [nixos.org](https://nixos.org/).

Setting up either a NixOS machine or a Nix-enabled Linux machine is
straightforward and is well documented on the
[official NixOS website](https://nixos.org/download/). You may use a complete
NixOS installation or another Linux distribution with the Nix package manager
installed. Both options are suitable for building the cluster.

During the setup process, you will build NixOS images for both the worker nodes
and the headnode. Once the cluster has been deployed, users will interact with
these NixOS systems through SSH or preferebly JupyterHub.

One of the following options may be convenient for your build environment:

- Install NixOS as a WSL2 distribution and run it "inside" your regular Windows
  installation.
- Use virtualization software such as VirtualBox to create a NixOS or
  Nix-enabled Linux VM on your host system.
- Use a dedicated physical Linux or NixOS machine.

Be aware that the build machine must be able to access USB devices. In the
simplest setup, you should also have physical access to the machine and the USB
drives.

Running the build machine as a virtual machine on a remote virtualization
platform, such as Proxmox VE, is possible. However, this introduces additional
challenges, including configuring USB passthrough, transferring generated
images, and writing those images to physical USB drives. Ensure that your chosen
build environment provides reliable access to the target storage devices before
beginning the deployment process.

## USB drives

Each node in the cluster requires a USB drive from which it can boot. The
generated images currently require significantly less than 8 GiB of storage, so
inexpensive USB drives with a capacity of at least 8 GiB should generally be
sufficient. However, using USB 3.0-compatible drives is recommended, as their
higher transfer speeds can considerably reduce the time required to write images
and boot the nodes.

USB 3.0 ports and drives are commonly identified by a blue plastic insert inside
the connector, although this convention is not used by every manufacturer.
Ensure that the cluster nodes support USB 3.0 and that the drives are connected
to compatible ports to benefit from the increased transfer speed.

The theoretical minimum number of nodes required for a functional
`small-data-cluster` is one: the headnode itself. A deployment may consist of a
single head node or one head node combined with any number of worker nodes. Each
node requires its own bootable USB drive.

> **Note:** Multiple `small-data-cluster` deployments can operate alongside one
> another. Internally, the clusters are distinguished by their respective
> Tailscale domains. Further information about this configuration is provided in
> the Tailscale section.
