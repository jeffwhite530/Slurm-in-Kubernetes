# Adding and Removing slurmd Nodes

**Warning:** Reducing the replica count will delete slurmd pods in Kubernetes. This can result in the loss of active jobs on the affected nodes, as the Kubernetes scheduler is unaware of Slurm's job queue or state.

The slurmd deployment can be scaled manually using:

```shell
kubectl scale deployment/slurm-cluster-slurmd --replicas=N
```

The Slurm Node Watcher pod will automatically register new slurmd pods with Slurm when they appear and remove them from Slurm when a pod is deleted. However, it is recommended to edit `helm/slurm-cluster/values.yaml` to set the number of replicas then upgrade the chart:

```yaml
pods:
    slurmd:
        replicas: 2
```

_Note: Add `-f secrets.yaml` if you have a secrets file._

```shell
helm upgrade slurm-cluster helm/slurm-cluster/
```
