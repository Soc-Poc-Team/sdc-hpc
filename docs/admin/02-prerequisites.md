# Prerequisites

We have streamlined the deployment of a `small-data-cluster` as much as
possible. However, several prerequisites must still be met. Work through this
section before beginning the deployment of a cluster.

## Nix-enabled build machine

The `small-data-cluster` is a Nix and NixOS-based project. Therefore, a machine
capable of executing Nix builds is required.

You can learn more about Nix and NixOS at [nixos.org](https://nixos.org/).

Setting up either a NixOS machine or a Nix-enabled Linux machine is
straightforward and is well documented on the
[official NixOS website](https://nixos.org/download/). You may use a complete
NixOS installation or another Linux distribution with the Nix package manager
installed. Both options are suitable for building the cluster.

During the setup process, you will build NixOS images for both the worker nodes
and the headnode. Once the cluster has been deployed, users will interact with
these NixOS systems through SSH or, preferably, JupyterHub.

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
single headnode or one headnode combined with any number of worker nodes. Each
node requires its own bootable USB drive.

> **Note:** Multiple `small-data-cluster` deployments can operate alongside one
> another. Internally, the clusters are distinguished by their respective
> Tailscale domains. Further information about this configuration is provided in
> the Tailscale section.

## Existing network

The `small-data-cluster` requires internet access during both deployment and
operation. During deployment, the build machine uses the internet to download
and build Nix packages. During operation, internet access is used to establish a
VPN mesh between the headnode, worker nodes, and—depending on your
configuration—client machines.

A "VPN mesh" is a private, encrypted network in which participating devices can
communicate with one another as though they were connected to the same local
network. See Tailscale’s
[introduction to mesh VPNs](https://tailscale.com/learn/understanding-mesh-vpns)
for more information.

The cluster does not depend on a particular local network topology or a specific
set of firewall rules. You should not need to adjust or worry too much about
your local network topology to run a `small-data-cluster`.

As long as every cluster node has unrestricted internet access with a reasonable
connection speed (approximately 50 Mbit/s or higher), no additional network
configuration should normally be required. However, be aware that the cluster
uses an external coordination service to establish and manage the VPN mesh
between its nodes.

In operational terms, unrestricted internet access means that the nodes can make
outbound connections directly. The network must not require a proxy, browser
login, captive portal, per-user authentication, or additional client software.
It must not block Tailscale coordination or peer-to-peer traffic, DNS
resolution, or downloads from the package and source services used during the
build. An organization that filters outbound traffic must verify that its rules
permit these operations.

The cluster nodes must be connected through a wired Ethernet network (commonly
also known as "LAN Port & LAN Cable"). The network connection must be available
automatically and must not require interactive authentication, a captive portal,
user-specific credentials, or manually installed client certificates.

The cluster has currently been tested only with one active wired Ethernet
connection per node. Other configurations with additional network interfaces may
work, but they are not officially tested. Such configurations may also stop
working after future updates.

> **Note:** Cluster updates must be applied manually by rebuilding the images
> and reflashing the USB drives. There are no automatic updates that could
> unexpectedly change the running cluster.

Worker nodes use the MAC address of the first detected network interface as
their identifier because MAC addresses are hardware-associated identifiers. See
[MAC address](https://en.wikipedia.org/wiki/MAC_address) for background
information.

## Tailscale

[Tailscale](https://tailscale.com/) is a networking service that creates a
private mesh VPN between authorized devices. A Tailscale network is called a
"tailnet". Devices within a tailnet communicate through encrypted connections
based on the [WireGuard](https://www.wireguard.com/) protocol, allowing cluster
nodes to reach one another without depending on the organization’s existing
network topology. This even works over multiple locations.

The `small-data-cluster` uses Tailscale to connect the headnode, worker nodes,
and optionally client machines through a common private network. This simplifies
deployment across different physical networks and locations. Tailscale provides
the external control plane used to authenticate devices, distribute network
information, and coordinate connections. The actual cluster traffic is encrypted
and is transferred directly between devices whenever possible.

Using an externally operated coordination service is a trade-off we made for
deployment simplicity and convenience. Your organization should evaluate whether
relying on this service is compatible with its security policies,
data-protection requirements, and operational constraints.

When the use of the hosted Tailscale control plane is not acceptable, you may
consider implementing an alternative based on
[Headscale](https://headscale.net/stable/). Headscale is an open-source,
self-hosted implementation of the Tailscale control server. However, Headscale
is not currently integrated into the standard `small-data-cluster` deployment
and requires changes to the project.

> **Note:** We are considering support for Headscale, but it is not currently
> planned for an upcoming release.

During the setup process, you will need to generate the Tailscale API access
token stored in `apiKey` and the authentication key stored in `authKey`. You
will also need your tailnet DNS name, referred to as the "Tailscale domain" in
parts of this project. This name commonly ends in `.ts.net` and identifies your
tailnet for DNS and API-related configuration.

We recommend [creating a Tailscale account](https://login.tailscale.com/start)
before starting with the cluster setup.

## Requirements summary

Before continuing, ensure that you have:

- A Nix-enabled Linux machine
- One USB drive per node
- A working internet connection
- A [Tailscale](https://tailscale.com) account

## Issues and pitfalls

This section describes known issues, common misconceptions, and potential
pitfalls for administrators. It will be expanded as additional limitations or
operational concerns are identified.

### Secure Boot

[Secure Boot](https://learn.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-secure-boot)
is a firmware security feature that allows a device to boot only software whose
digital signature is trusted by the system firmware. It is intended to reduce
the risk of unauthorized or modified bootloaders being executed during startup.

Secure Boot may be enabled on machines intended for use with the
`small-data-cluster`. At the current stage of development, the project does not
provide signed boot images or a supported procedure for enrolling custom signing
keys. As a result, cluster nodes may fail to boot while Secure Boot is enabled.

You must therefore disable Secure Boot in the device’s UEFI or firmware settings
before booting a `small-data-cluster` image. Where organizational policies
permit it, Secure Boot may be disabled temporarily for testing or permanently on
machines dedicated exclusively to the cluster.

Disabling Secure Boot removes one layer of protection against unauthorized
modifications to the boot process. This decision should therefore be reviewed in
the context of your organization. Cluster hardware should be physically
protected against unauthorized access or tampering, and access to firmware
settings should be restricted where possible. Physical protection alone,
however, does not fully replace the security guarantees provided by Secure Boot.

The exact procedure for disabling Secure Boot depends on the device manufacturer
and firmware version. Consult the manufacturer’s documentation or search for
instructions using terms such as:

`Disable Secure Boot on <device model>`

For example:

`Disable Secure Boot on Dell OptiPlex <model number>`
