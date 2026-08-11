# Operate the cluster

At this point, you should have a running `small-data-cluster` consisting of one
headnode and, optionally, one or more worker nodes.

This chapter explains the available interfaces, how users can access the
cluster, and how to perform basic health checks. It also introduces the
user-facing services provided by the headnode.

## Interfaces

You can interact with the `small-data-cluster` in three primary ways:

- Connect to a node over SSH.
- Use a local terminal on a node.
- Use the web interface provided by the headnode.

For regular users, the web interface is the recommended way to access the
cluster. Administrators and experienced users may prefer SSH for diagnostics and
command-line operations.

### Connect over SSH

Every node runs an SSH server. SSH provides encrypted remote command-line access
to another machine.

When your workstation is connected to the same Tailscale tailnet as the cluster,
you can connect to a node using its Tailscale hostname. For example, connect to
the headnode with:

```console
ssh <username>@headnode
```

Replace `<username>` with a user defined in the cluster configuration.

After connecting, you receive a fish shell on the selected node. You can use it
for normal command-line operations, inspect the cluster state, or submit
workloads to Slurm.

For example, Slurm provides `srun` for starting interactive or immediate
workloads and `sbatch` for submitting batch scripts. Refer to the
[Slurm Quick Start User Guide](https://slurm.schedmd.com/quickstart.html) for an
introduction to these and other Slurm commands.

SSH access over the physical LAN may also be possible, depending on the local
network configuration and name resolution. The Tailscale connection is the
expected method for remote access and does not depend on the local network
providing DNS entries for cluster nodes.

### Use a local terminal

You can also interact with a node directly by connecting a keyboard and monitor.

During normal operation, each node automatically signs in to a local terminal as
the `nixos` user. The `nixos` account has `sudo` privileges and can therefore
perform administrative operations on the node.

> **Security warning:** Anyone with physical access to a running node may be
> able to use the automatically logged-in `nixos` account and gain
> administrative privileges. Restrict physical access to cluster hardware
> accordingly.

Users configured through the cluster configuration are also currently members of
the `wheel` group. Membership in this group allows them to use `sudo` and gain
administrative privileges.

This behavior is intentional in the current implementation. A future version may
provide configuration options that distinguish administrative users from users
without `sudo` access.

> **Security warning:** Treat every configured cluster user as an administrator.
> A user with `sudo` access can modify the system, access data belonging to
> other users, and interfere with workloads or services. Only create accounts
> for people who are trusted with administrative access to the entire cluster.

### Use the web interface

When your workstation is connected to the cluster's tailnet, open the following
address in a web browser:

```text
http://headnode
```

The headnode serves a dashboard that provides links to the web services
available on the cluster. These services include JupyterHub and Grafana.

The dashboard itself is primarily an entry point. The individual services
provide the functionality for interactive computing, monitoring, and other
cluster operations.

### JupyterHub

[JupyterHub](https://jupyterhub.readthedocs.io/) provides a multi-user web
environment for Jupyter notebooks. It allows users to sign in through a browser
and work with notebooks, terminals, files, and computational environments
without requiring them to interact directly with the cluster's command-line
tools. For this reason, JupyterHub is the primary interface intended for users
who are not familiar with Linux administration, SSH, or Slurm.

In the `small-data-cluster`, Jupyter environments are started as Slurm workloads
and can therefore execute on the resources managed by the cluster. The user's
home and working files are provided through the shared NFS filesystem hosted by
the headnode. This filesystem currently resides in the headnode's RAM. As a
result, notebook execution and file storage are separate concerns: a notebook
may execute on a worker node while its working files remain available through
the shared filesystem.

> **Important:** The shared filesystem resides in the headnode's RAM. Treat its
> contents according to the project's documented persistence and backup
> limitations. Ddata stored there does not survive shutdowns or reboots of the
> headnode, reboot, failure, or administrative operation unless the relevant
> persistence behavior has been explicitly implemented or you are using external
> storage (like S3 etc)

A later section describes how to use the provided Jupyter environments,
available kernels, and cluster-specific notebook behavior in more detail.

## Verify cluster health

Slurm is one of the core components of the `small-data-cluster`. It acts as the
cluster's workload manager and job scheduler. Slurm tracks available compute
resources, manages worker nodes, and schedules submitted jobs onto those
resources.

You can perform an initial health check from a terminal on the headnode or
another node with access to the Slurm controller.

Run:

```console
sinfo
```

The `sinfo` command displays information about the Slurm partitions and the
nodes known to the scheduler.

A healthy cluster should list the expected worker nodes. Pay particular
attention to the node state. Nodes that are available for work normally appear
in an idle or mix state, depending on whether they are currently running jobs.

Use:

```console
sinfo -N -l
```

to display more detailed information for individual nodes.

You can also inspect jobs currently known to Slurm with:

```console
squeue
```

If no jobs have been submitted, `squeue` may display only its column headings.
This is normal and does not indicate a problem.

For detailed information about Slurm commands and node states, refer to the
[Slurm Quick Start User Guide](https://slurm.schedmd.com/quickstart.html) and
the [`sinfo` command reference](https://slurm.schedmd.com/sinfo.html).
