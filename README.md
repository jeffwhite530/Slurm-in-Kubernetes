
This repo contains code to build and deploy a Slurm cluster using containers. It includes:

- **HashiCorp Packer Templates**: Building and managing machine and app images
- **Ansible Playbooks**: Automating system configuration and service deployment
- **Kubernetes Manifests**: Orchestrating containerized apps
- **Helm Charts**: Packaging and deploying Kubernetes applications

## Setup

1. Install required tools

   Ensure the tools are installed on your system:
   - Ansible
   - Docker
   - Hashicorp Packer
   - kubectl (and already configured for your Kubernetes cluster)
   - Helm

1. Build the Slurm container image.

   ```shell
   cd packer

   packer init build-slurm.pkr.hcl

   packer build build-slurm.pkr.hcl
   ```

1. Create helm/secrets.yaml and set your database username/pass.

   ```plaintext
   mariadb:
     secret:
       username: "slurm"
       password: "your-actual-password-here"
   ```

1. Edit helm/slurm-cluster/values.yaml with your preferences and validate the helm chart values.

   ```shell
   cd helm

   helm template slurm-cluster slurm-cluster/ \
   --namespace slurm-cluster \
   -f secrets.yaml > rendered-manifests.yaml
   ```

1. Update helm dependencies.

   ```shell
   cd helm/slurm-cluster
   helm dependency update
   cd ../
   ```

1. Deploy the Kubernetes resources.

   ```shell
   cd helm

   kubectl create namespace slurm-cluster

   helm install slurm-cluster slurm-cluster/ \
   --namespace slurm-cluster \
   -f secrets.yaml
   ```

1. Verify the helm release status

   ```shell
   helm ls -n slurm-cluster
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

   1. List the Slurm nodes.

      ```shell
      kubectl exec -n slurm-cluster -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -c slurmctld -- sinfo
      ```

      ```plaintext
      PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
      main*        up   infinite      1   idle slurmd-879764659-nkz29
      ```

      ```shell
      kubectl exec -n slurm-cluster -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -c slurmctld -- scontrol show node slurmd-879764659-nkz29
      ```

      ```plaintext
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

   1. Copy a job script into a container.

      ```shell
      kubectl cp scripts/hello-job.sh slurm-cluster/$(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}'):/tmp/hello-job.sh
      ```

   1. Submit a job as the slurm user.

      ```shell
      kubectl exec -n slurm-cluster -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') \
      -c slurmctld -- su - slurm -c "sbatch /tmp/hello-job.sh"
      ```

   1. Check the job status.

      ```shell
      kubectl exec -n slurm-cluster -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -c slurmctld -- squeue

      kubectl exec -n slurm-cluster -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -c slurmctld -- sacct --format=JobID,JobName,State,NodeList%25,StdOut,StdErr
      ```

      ```plaintext
      JobID           JobName      State                  NodeList               StdOut               StdErr
      ------------ ---------- ---------- ------------------------- -------------------- --------------------
      1             debug-job    PENDING             None assigned      /tmp/job-%j.out      /tmp/job-%j.err
      2             debug-job  COMPLETED    slurmd-879764659-nkz29      /tmp/job-%j.out      /tmp/job-%j.err
      2.batch           batch  COMPLETED    slurmd-879764659-nkz29
      3             debug-job  COMPLETED    slurmd-879764659-nkz29      /tmp/job-%j.out      /tmp/job-%j.err
      3.batch           batch  COMPLETED    slurmd-879764659-nkz29
      ```

   1. Check the job's output file. Use the node (container name the job ran in) and log file from sacct above.

      ```shell
      kubectl exec -n slurm-cluster -it slurmd-879764659-nkz29 -c slurmd -- cat /tmp/job-3.out
      ```

1. Scale-up the cluster by adding more worker nodes.

   ```shell
   kubectl scale deployment slurmd --replicas=5 -n slurm-cluster
   ```

   ```shell
   kubectl exec -n slurm-cluster -it $(kubectl get pod -l app=slurmctld -n slurm-cluster -o jsonpath='{.items[0].metadata.name}') -c slurmctld -- sinfo
   ```

   ```plaintext
   PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
   main*        up   infinite      5   idle slurmd-879764659-2cmks,slurmd-879764659-4gvnj,slurmd-879764659-b4q5d,slurmd-879764659-nkz29,slurmd-879764659-qlnh6
   ```

## Teardown

1. Delete the Kubernetes resources.

```shell
helm uninstall slurm-cluster -n slurm-cluster
kubectl delete namespace slurm-cluster
```
