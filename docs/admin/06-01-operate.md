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

> **Warning:** The shared filesystem resides in the headnode's RAM. Its contents
> do not survive a shutdown, reboot, or failure of the headnode. Move results
> that you need to keep to external persistent storage before stopping the
> cluster.

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

## Store files on the cluster

The `small-data-cluster` provides a shared filesystem through the Network File
System (NFS). NFS allows one machine to make a directory available to other
machines over a network. Programs can then read and write files in that
directory much as they would use a local disk.

The headnode provides the `/homes` directory as the NFS server. Every worker
node mounts the same directory at `/homes`. A file written to `/homes` on one
node is therefore available at the same path on the other nodes. This shared
path allows a Slurm job or Jupyter environment running on a worker to access a
user's files.

Configured cluster users have their home directories at `/homes/<username>`.
This differs from the conventional `/home/<username>` path. Local system
accounts that are not part of the cluster configuration, such as the live
system's `nixos` account, may still use `/home`.

You can use your directory under `/homes` for notebooks, scripts, job logs,
temporary results, and datasets that fit within the available memory. JupyterHub
also uses it as the notebook directory and stores each notebook server's Slurm
log there.

> **Warning:** In the current live system, `/homes` resides in the headnode's
> RAM. Its contents are lost when the headnode shuts down, reboots, or fails.
> Copy any file that you need to keep to persistent storage before stopping the
> headnode. NFS makes the directory available across the cluster; it does not
> make the data persistent or create a backup.

Large datasets can also consume memory needed by the headnode's services. For
larger or persistent datasets, use an external storage service or storage server
that the cluster can reach over the network. The current configuration does not
mount or configure external storage automatically. You must arrange the
connection, credentials, access controls, and backups required by the selected
storage system.

## Monitor the cluster with Grafana

Grafana presents metrics and logs collected from the cluster as web dashboards.
Open the headnode dashboard at `http://headnode`, and then select **Grafana**.
Grafana permits anonymous read-only access in the current configuration, so you
can inspect the provisioned dashboards without signing in.

The dashboards update as Prometheus collects new metrics. Use Grafana's time
range and refresh controls in the upper-right corner when investigating current
activity or an earlier event.

### `small-data-cluster` dashboard

Use the `small-data-cluster` dashboard for a high-level operational overview. It
combines the following cluster information:

- Headnode CPU, memory, and network activity.
- Overall CPU and memory allocation reported by Slurm.
- Slurm job states and worker node states over time.
- Logs from the headnode's `slurmctld` and `jupyterhub` systemd services.

Start with this dashboard when checking capacity, node availability, or the
general health of the cluster. The log panels are useful when a job cannot be
scheduled or a Jupyter environment does not start. Expand a panel or narrow the
time range to inspect an event in more detail.

### Node Exporter Full dashboard

The **Node Exporter Full** dashboard shows operating-system metrics for one
machine at a time. Prometheus collects these metrics from the headnode and from
worker nodes discovered through Slurm.

Select a machine from the **Nodename** list at the top of the dashboard. Use the
panels to inspect information such as:

- CPU utilization, load, and time spent waiting for input and output.
- Available and used memory, including cache and swap where present.
- Filesystem capacity and filesystem input/output activity.
- Network traffic and errors by interface.
- System uptime and the state of systemd services.

This dashboard helps distinguish a machine-level resource problem from a Slurm
scheduling problem. For example, sustained CPU use may be expected while a job
runs, while low available memory or a nearly full filesystem may require
administrative attention. Some panels may remain empty when the underlying
hardware, filesystem, or collector is not present on the selected node.

### Slurm Dashboard

The **Slurm Dashboard** provides detailed scheduler and workload information. It
includes partition capacity and load, node states, job counts, CPU and memory
allocation by account or user, job resource usage, and Slurm controller remote
procedure call (RPC) activity.

Use the dashboard's partition, job-state, user, account, and job selectors to
narrow the displayed data. The job panels can help compare allocated resources
with observed CPU, memory, and input/output use. The controller diagnostics can
help identify unusually frequent or slow RPC requests. Empty account, user, or
job panels usually mean that no matching workload exists in the selected time
range.

Grafana is an observation interface. It does not change Slurm node or job
states. Use command-line tools such as `sinfo` and `squeue` to confirm the
current scheduler state before taking administrative action.

## Use JupyterHub

**TODO:** Add an in-depth guide to signing in to JupyterHub, selecting a
resource profile, starting and stopping a notebook server, using the provided
`small-data-cluster` kernel, and understanding where the notebook process runs.
