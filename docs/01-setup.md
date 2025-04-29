# Live-ISO

The Live-ISO is ideal for trying out running a cluster on your existing
hardware. It is does not persist data between sessions. Since all data is stored
in RAM, it is not persisted. If you want to persist data between reboots, refer
to the [disko](./02-burn-to-disk.md#disko) section.

## Building the ISO

This repository does not provide a pre-built ISOs. You will have to build them
yourself. Currently we support building the ISOs via gitlab and github CI/CD
pipelines, or building them locally on your system.

#### CI/CD

If you are running your own gitlab runner or are using the github runners,
pushing changes of the `config.toml` or any of the nix files triggers a pipeline
that builds the ISOs. When the building process is finished, your ISOs can be
downloaded from your repository. Currently github has space for both isos as
artifacts. Gitlab does not offer enough space, if you selfhost a gitlab instance
you can ask your administrator to allow for artifacts with roughly 5GB in size.

#### Locally

To build the ISOs locally, you have to install
[nix](https://nixos.org/download/) on your system.

Then you can build the headnode ISO by running `nix build` and the worker ISO by
running `nix build .#worker`. The resulting ISOs can be found under
`./result/iso/`.
