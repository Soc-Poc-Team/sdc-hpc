# Introduction

Welcome to the administrator documentation for the `small-data-cluster`. First,
we would like to thank you for checking out our project. Please note that the
`small-data-cluster` is still a research project and currently receives only
limited support from our team.

## What does the SDC offer you and your company?

Many companies in Germany do not fully use the data available to them to
optimize their processes or learn more about their products, customers, and
operations.

The SDC provides an on-demand high-performance computing environment using
hardware you already own. It offers a simple yet powerful platform for running
small HPC workloads, such as data analysis. [TODO: Add source]

The `small-data-cluster` is distributed as a Git repository that you can easily
check out, configure, and build. You can begin deploying it to your hardware in
less than 30 minutes.

## Considerations

Because this is an active research project that is still under development, you
should carefully evaluate its security implications before using the cluster
software in a production environment.

Carefully consider who has access to the secrets used to build your images.
Anyone who has access to any of the following may gain full access to, or even
control over, your cluster:

- The `/nix/store` directory on the machine used to compile the images
- A copy of the ISO images, including any physical drives onto which the images
  were written
- The `config.toml` file in your checked-out repository, unless secrets are
  managed using SOPS

### Shared file-system access and data confidentiality

Be aware that every worker node may have access to the head node’s shared file
system. Depending on the cluster configuration, this may allow users, workloads,
or compromised worker nodes to read, modify, delete, or extract files stored
within the shared file system.

The shared file system must therefore be treated as part of the cluster’s
trusted computing environment and as a potential attack surface. Isolation
between worker nodes, users, jobs, and datasets should not be assumed unless it
has been explicitly configured, tested, and independently verified.

A compromised account, workload, worker node, credential, image, or
administrative system may result in unauthorized access to confidential
information or other cluster resources. Data accessible through the shared file
system may also be exposed through incorrectly configured permissions, malicious
workloads, vulnerable dependencies, or unintended interactions between
concurrent jobs.

When confidential, personal, regulated, proprietary, or otherwise sensitive data
is stored or processed on the cluster, access should be restricted to authorized
and trusted individuals. This includes physical access to machiens and flash
media. Apply the principle of least privilege!

You should also consider implementing additional safeguards, including:

- File and directory permissions appropriate to each user and workload
- Separation of users, projects, and datasets
- Encryption of sensitive data at rest and in transit (probably external data
  sources)
- Secure management and regular rotation of credentials and secrets
- Logging, monitoring, and auditing of access to sensitive resources
- Regular vulnerability assessments

Do not rely on the systems implemented in the `small-data-cluster` as the sole
security control for sensitive data or critical operations. Before using the
cluster in a production environment, conduct your own security assessment and
verify that the deployment complies with your organization’s internal policies
and all applicable legal, contractual, regulatory, and data-protection
requirements.

## Security and integrity disclaimer

**The `small-data-cluster` is an experimental research project provided without
any guarantee of security, availability, reliability, confidentiality,
correctness, or data integrity.**

To the extent permitted by applicable law, the project maintainers provide the
software on an “as is” and “as available” basis, without warranties or
representations of any kind. This includes, without limitation, warranties
concerning fitness for a particular purpose, merchantability, non-infringement,
compatibility, uninterrupted operation, or protection against unauthorized
access, data loss, corruption, disclosure, or system compromise.

You are solely responsible for evaluating whether the software is suitable for
your intended use, configuring and operating it securely, controlling access to
the cluster, protecting credentials and data, maintaining backups, monitoring
the deployment, and responding to security incidents.

Use of the software does not transfer responsibility for compliance, risk
management, data protection, or operational security to the project maintainers
or contributors. No documentation, configuration example, recommendation, or
statement made by the project should be interpreted as a guarantee that a
deployment is secure or compliant.

Do not use the software for safety-critical, mission-critical, or legally
regulated workloads unless you have completed an appropriate technical,
security, operational, and legal review and have implemented sufficient
independent safeguards.
