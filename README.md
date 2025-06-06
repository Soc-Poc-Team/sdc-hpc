![login screen](./docs/login-screen.png)

## Disclaimer

- ⚠️ The project is under active development.
- ⚠️ Expect bugs and breaking changes.
- ⚠️ Please backup your code and data.

## Description

Dynamic on-demand cluster for small and medium sized enterprises on commercial off-the-shelf hardware.

## Motivation

Data science may improve existing processes and work, for example in quality control.
However, in our experience working with small- and medium-sized enterprises (SMEs), high investment
costs and data security concerns often prevent companies from applying Data Science to their
use cases.

The goal of this project is to reduce the investment cost of cluster infrastructure, since this could
motivate the exploration of data science and machine learning solutions by SMEs.

## Approach

The Approach of this project is to build a reproducible and scalable Plug & Play Live-ISO with minimal configuration
requirements that runs a multi purpose cluster on existing infrastructure in the SMEs, serving well established
tools and frameworks that enable users to develop and train machine learning models. Thus, SMEs can use e.g.
the developers’ machines during off-business hours to train machine learning models, without the need for dedicated
hardware or cloud solutions. This reduces overall costs and contributes to data security and protection of intellectual property.

## Getting started

This project is designed to be Plug & Play. Since it is deployed via Live-ISOs, it **does not** affect the operating systems deployed on your existing hardware.

This design decision has the drawback that it is not possible to persist data between reboots. This means any changes you make, every file you create are discarded on reboot.

If you require data persistance, you have the option of dedicating a whole drive to the headnode. Refer to the [disko](#disko) section for this.

Which version you should choose depends on your requirements.

As a quick overview, with the following steps you will be able to run you own cluster on your own hardware.

Building locally:

1. Install Nix package manager
2. Adjust config.toml to your needs
3. Run `nix build` and `nix build .#worker`
4. Burn the ISOs to a boot medium, plug them in and boot into them.

or via CI/CD pipeline:

1. Fork this repository
2. Adjust config.toml to your needs
3. Commit changes to trigger build-pipeline
4. Download the ISOs from your git platform
5. Burn the ISOs to a boot medium, plug them in and boot into them.

### Configure your cluster

The only file you have to adjust to run your own cluster is the [config.toml](/config.toml). The file provided
by this repo serves as an example and can be adjusted to your needs.

#### Tailscale

This project uses tailscale to allow nodes to communicate with each other. Enter your tailscale authentication-key (to get access to your tailnet), your
API-key (to manage the tailnet) and your tailscale domain into the config file.

#### Users

You can create users by adding them to the [config.toml](/config.toml). They require a username, password-hash and a UUID. These users
will be able to login to jupyter hub and have a linux users with these credetials.

This is how you generate your password-hashes

```bash
mkpasswd -m sha-512
```

### Live-ISO

The Live-ISO is ideal for trying out running a cluster on your existing hardware. It is does not persist data between sessions.
Since all data is stored in RAM, it is not persisted. If you want to persist data between reboots, refer to the [disko](#disko) section after running the headnode's Live-ISO.

#### Building the ISO

This repository does not provide a pre-built ISOs. You will have to build them yourself. Currently we support building the ISOs via gitlab and github CI/CD pipelines, or building them locally on your system.

##### CI/CD

If you are running your own gitlab runner or are using the github runners, pushing changes of the `config.toml` or any of the nix files triggers a pipeline that builds the ISOs. When the building process is finished, your ISOs can be downloaded from your repository.

##### Locally

To build the ISOs locally, you have to install [nix](https://nixos.org/download/) on your system.

Then you can build the headnode ISO by running `nix build` and the worker ISO by running `nix build .#worker`. The resulting ISOs can be found under `result/iso/`.

#### Burning the ISOs to USB sticks

Next you have to burn the ISOs to seperate boot media (e.g. USB-sticks). Replace `ID_OF_YOUR_BOOT_DEVICE_1` and `ID_OF_YOUR_BOOT_DEVICE_2` with the actual id of your boot device you want to burn the ISO to.

```bash
ISO=headnode.iso
# writing ISO
sudo dd if=result/iso/$ISO of=/dev/disk/by-id/ID_OF_YOUR_BOOT_DEVICE_1 status=progress && sync

ISO=workernode.iso
sudo dd if=result/iso/$ISO of=/dev/disk/by-id/ID_OF_YOUR_BOOT_DEVICE_2 status=progress && sync
```

#### Plug & Play

You can now plug your boot device into your existing hardware, select them via the boot menue and wait for your cluster to boot.

#### disko

The headnode Live-ISO provides a script which turns the Live-ISO into a fully fledged NixOS installation. It also partitions the harddrive into bootloader, NixOS, and data partition.
This enables data persistance. You can still use the resulting drive on any hardware, but instead of holding data only in RAM, it is now stored within the data partition. In other words, you can take your data with you. This still does not affect the operating systems on your existing hardware, but now your deployment is not stateless anymore.

Note that you can install this on the same harddrive you use to run the headnode Live-ISO. You do not require multiple harddrives.

## Development

This project provides a developer shell. You can enter it with `nix develop`.

## Requirements

- headnode and workernode ISO must be build from the same pc. This is because of /nix/store/

## Research project

This is a research project. Thus we are interested in gathering basic, anonymous usage data to measure interest in this project.

Example datapoint that we periodically send on each deployed cluster to our backend:

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

We do not gather any other data.

Telemetry can be opted out by setting `telemetry = false` in your config.toml.

## Acknowledgements

We acknowledge the support by the Federal Ministry of Education and Research (BMBF) under grant number 02L19C602 (project WIRKsam)
