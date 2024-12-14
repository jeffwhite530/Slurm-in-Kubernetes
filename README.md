
This repo contains code to build and deploy a Slurm cluster using containers. It includes:

- **Ansible Playbooks**: Automating system configuration and service deployment
- **Kubernetes Manifests**: Orchestrating containerized apps
- **HashiCorp Packer Templates**: Building and managing machine and app images

## Setup

1. **Install required tools**
   Ensure the tools are installed on your system.
   - Ansible
   - Docker
   - Hashicorp Packer

1. Build the Slurm container image.
```shell
cd packer
packer init build-slurm.pkr.hcl
packer build build-slurm.pkr.hcl
```

1. Create a Kubernetes namespace to deploy Slurm in.
```shell
kubectl create namespace slurm-cluster --save-config
```

1. Create opaque secrets and update `kubernetes/secrets.yaml`.
```shell
echo -n 'P@ssword!' | base64
```

1. Update the PersistentVolume in `kubernetes/slurm-cluster.yaml` to where you want to store your data.

1. Deploy the Kubernetes resources.
```shell
cd kubernetes
kubectl apply -f secrets.yaml
kubectl apply -f slurm-cluster.yaml
```

1. Verify the pods launched.
```plaintext
$ kubectl -n slurm-cluster get all
NAME                             READY   STATUS    RESTARTS   AGE
pod/mariadb-597dd4cd4b-kjfjx     1/1     Running   0          31h
pod/slurmctld-57954475b4-c6dql   1/1     Running   0          16m
pod/slurmd-879764659-nkz29       1/1     Running   0          10m
pod/slurmdbd-5744d655bd-mbxv8    1/1     Running   0          31h

NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/mariadb     ClusterIP   10.96.248.12    <none>        3306/TCP   31h
service/slurmctld   ClusterIP   10.106.97.100   <none>        6817/TCP   31h
service/slurmdbd    ClusterIP   10.99.42.161    <none>        6819/TCP   31h

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/mariadb     1/1     1            1           31h
deployment.apps/slurmctld   1/1     1            1           31h
deployment.apps/slurmd      1/1     1            1           31h
deployment.apps/slurmdbd    1/1     1            1           31h

NAME                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/mariadb-597dd4cd4b     1         1         1       31h
replicaset.apps/slurmctld-57954475b4   1         1         1       16m
replicaset.apps/slurmd-879764659       1         1         1       10m
replicaset.apps/slurmdbd-5744d655bd    1         1         1       31h
```

1. Check the Slurm cluster status.
   Exec into the slurmctld container
```shell
kubectl -n slurm-cluster exec -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -c slurmctld -- /bin/bash
```

   List the Slurm nodes
```plaintext
root@slurmctld:/# scontrol show nodes
NodeName=slurmd-879764659-nkz29 Arch=x86_64 CoresPerSocket=1
   CPUAlloc=0 CPUEfctv=2 CPUTot=2 CPULoad=8.73
   AvailableFeatures=(null)
   ActiveFeatures=(null)
   Gres=(null)
   NodeAddr=10.10.1.238 NodeHostName=slurmd-879764659-nkz29 Version=24.11.0
   OS=Linux 6.1.0-26-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.112-1 (2024-09-30)
   RealMemory=4096 AllocMem=0 FreeMem=53921 Sockets=2 Boards=1
   State=IDLE+DYNAMIC_NORM ThreadsPerCore=1 TmpDisk=0 Weight=1 Owner=N/A MCS_label=N/A
   Partitions=main
   BootTime=2024-11-29T13:04:40 SlurmdStartTime=2024-12-13T00:36:06
   LastBusyTime=2024-12-13T00:36:06 ResumeAfterTime=None
   CfgTRES=cpu=2,mem=4G,billing=2
   AllocTRES=
   CurrentWatts=0 AveWatts=0
```

1. Launch a test Slurm job.

```shell
cat <<EOF > scripts/hello-job.sh
#!/bin/bash
#SBATCH --job-name=hello-job
#SBATCH --output=/tmp/job-%j.out
#SBATCH --error=/tmp/job-%j.err
#SBATCH --ntasks=1
#SBATCH --mem=1G
#SBATCH --partition=main

echo "Starting job on $(date)"
echo "Running on hostname: $(hostname)"
echo "Job ID: $SLURM_JOB_ID"
echo "Job name: $SLURM_JOB_NAME"
echo "Allocated nodes: $SLURM_JOB_NODELIST"
echo "Number of CPUs allocated: $SLURM_CPUS_ON_NODE"

echo "Hello from $(hostname)!"

echo "Job completed on $(date)"
EOF

kubectl cp scripts/hello-job.sh slurm-cluster/$(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}'):/tmp/hello-job.sh

kubectl exec -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -n slurm-cluster -c slurmctld -- sbatch /tmp/hello-job.sh

kubectl exec -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -n slurm-cluster -c slurmctld -- squeue

```
