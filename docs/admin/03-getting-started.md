# Getting Started

This chapter guides you through the steps required to prepare for the deployment
of your own `small-data-cluster`.

Before proceeding, we strongly recommend reading the previous chapter in full.
In particular, administrators planning to deploy a `small-data-cluster` in a
professional or production environment should carefully review the provided
security information and assess the associated risks.

Unfortunately, we cannot provide universal support for every hardware
configuration, network environment, or deployment scenario. Some troubleshooting
and adaptation may therefore be required. The software tries its best to work in
any environment it is deployed in.

## Assumptions

The following instructions assume that you have:

- A Nix-enabled Linux or NixOS machine
- A working internet connection
- An account with `sudo` privileges

All subsequent steps are based on these assumptions.

## Enable Experimental Nix Features

Nix is a programming language, package manager, and the foundation of the NixOS
operating system. Some commonly used Nix features are still classified as
experimental and must be explicitly enabled before they can be used.

The `small-data-cluster` relies on these features during the build and
configuration process. We will enable them globally for your Nix installation so
that they do not need to be specified separately in every command.

> **Note:** Enabling experimental Nix features affects all users and Nix
> commands on the machine. On shared systems, ensure that this configuration
> change is acceptable to the system administrator.

### On NixOS
