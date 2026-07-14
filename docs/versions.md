# Small Data Cluster Versioning

The Small Data Cluster (SDC) uses a shared versioning scheme to describe the
capabilities and compatibility of both worker nodes and the head node.

The headnode determines which SDC versions are allowed to join the cluster
(enforced by pharos & pharosd). This prevents incompatibilities caused by
changes such as different Nix store paths, communication stack updates, or other
breaking modifications.

The cluster version is embedded into the images at build time. It is read from
the `VERSION` file located in the repository root.

## Version Specification

This section defines the SDC versioning scheme and its compatibility guarantees.

### Version 1.0 ("No Version")

The initial iteration of the project did not implement a versioning system. For
documentation purposes, this release is referred to as version **1.0**.

All subsequent releases start at **2.0**.

### Version Format

SDC versions follow a format inspired by
[Semantic Versioning](https://semver.org), but adapted to the project's
compatibility requirements.

Version strings use the following format:

```text
MAJOR.MINOR(.PATCH)
```

The `PATCH` component is optional.

Each version component must be incremented by exactly **1** when advancing to
the next version.

### Compatibility Rules

The version components have the following meaning:

- **Major** – Expected to be **incompatible** with previous major versions.

  - Examples:

    - Upgrading to a new NixOS release
    - Changes related to internode communication or software stack between nodes
    - Any architectural change that prevents interoperability

- **Minor** – User-visible behavior should remain largely the same, but
  compatibility is **not guaranteed**.

  - Minor releases may update flake inputs, resulting in different Nix store
    paths or other implementation changes that can prevent mixed-version
    clusters from functioning correctly.

- **Patch** – Expected to be **fully compatible**.

  - Patch releases must not change software versions, public behavior,
    communication, or any other aspect that could affect interoperability
    between nodes.
