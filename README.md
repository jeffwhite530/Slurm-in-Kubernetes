# Slurm in Kubernetes

This project provides a containerized Slurm cluster solution running on Kubernetes.

## Features

- **Automatic Installation**: Automated deployment of Slurm's components and worker nodes (pods).
- **Database Integration**: Preconfigured MariaDB backend for job accounting and reporting.
- **Extensible**: Flexible deployment via Helm, with support for diverse storage configurations, including automatic provisioning of persistent volumes (PVs) or integration with pre-defined PVs.
- **Common Foundation**: Built with [Debian](https://hub.docker.com/_/debian), [MariaDB](https://mariadb.org/), and [Slurm](https://github.com/SchedMD/slurm).

## How to Install

Documentation can be found here: <https://jeffwhite530.github.io/Slurm-in-Kubernetes>

## License

This project is licensed under a BSD 3-Clause license.
