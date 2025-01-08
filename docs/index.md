# Slurm in Kubernetes

This project provides a containerized Slurm cluster solution running on Kubernetes.

## Features

- **Automatic Installation**: Automated deployment of Slurm's components and worker nodes (pods).
- **Database Integration**: Preconfigured MariaDB backend for job accounting and reporting.
- **Extensible**: Flexible deployment via Helm, with support for diverse storage configurations, including automatic provisioning of persistent volumes (PVs) or integration with pre-defined PVs.
- **Common Foundation**: Built with [Debian](https://hub.docker.com/_/debian), [MariaDB](https://mariadb.org/), and [Slurm](https://github.com/SchedMD/slurm).

## Components

These components are launched by the system as Kubernetes pods.

- **MariaDB**: Backend database for Slurm job accounting.
- **slurmdbd**: Handles Slurm's database communication.
- **slurmctld**: Slurm's central scheduler managing jobs and resources.
- **slurmd**: Compute node agent that executes jobs.
- **Slurm Node Watcher**: Syncs Kubernetes pods with Slurm nodes.

Additionally, a munge daemon is integrated into components to facilitate secure authentication with Slurm.
