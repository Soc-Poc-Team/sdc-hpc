# Workflow

This chapter describes the recommended workflow for getting started with the
`small-data-cluster`.

## Prerequisites

Before you start development, ensure that you have:

- A Nix-enabled workstation. See the administration manual for instructions on
  setting up a suitable workstation.
- Working knowledge of Git and its basic workflow.
- A general understanding of the Nix language and the Nix package ecosystem.

## Check out the repository

The `small-data-cluster` is hosted in two repositories on separate GitLab
instances operated by FH Aachen.

The primary repository is hosted on the FH Aachen enterprise GitLab instance:

[Primary `small-data-cluster` repository](https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster)

This repository contains project metadata, including work items, and should
remain private.

A public mirror is hosted on the FH Aachen Community GitLab instance:

[Public `hpc-on-demand` mirror](https://git-ce.fh-aachen.de/bigdatalab/hpc-on-demand)

The repositories currently use different names because the final project name
has not yet been decided.

The primary repository is configured to push-mirror all commits from all
branches to the public repository. The mirror uses a deployment token from the
Community GitLab instance.

> **Security warning:** Commits pushed to the private primary repository are
> mirrored to the public repository. Do not commit or push credentials, private
> information, internal work-item content, or other data that must not become
> public.

> **Warning:** Do not push directly to the public mirror. Direct changes can
> cause the configured push mirror to fail, including changes that appear not to
> conflict with the primary repository.

Clone the primary `small-data-cluster` repository to your Nix-enabled
workstation:

```bash
git clone https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster.git
```

Alternatively, clone the repository over SSH:

```bash
git clone git@git.fh-aachen.de:bigdata/cape-canaveral/small-data-cluster.git
```

> **Note:** SSH access requires connecting from inside the FH Aachen network.
> Fun Fact: This security restriction was put into place after AI training from
> Anthropic and co started scraping my personal public repos on our gitlab and
> produced milions of requests causing our gitlab server to crash and be
> unavailable from time to time for about 2 weeks in 2026...
