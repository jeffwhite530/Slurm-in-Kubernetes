
This repo contains code to build and deploy a Slurm cluster using containers. It includes:

- **Ansible Playbooks**: Automating system configuration and service deployment
- **Kubernetes Manifests**: Orchestrating containerized apps
- **HashiCorp Packer Templates**: Building and managing machine and app images

## Setup

1. **Install Ansible and kubectl**  
   Ensure both tools are installed on your system.

2. Build the Slurm container image.
```shell
cd packer
packer init build-slurm.pkr.hcl
packer build build-slurm.pkr.hcl
```
