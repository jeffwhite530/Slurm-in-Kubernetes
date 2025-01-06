# Deploying

## Prerequisites

Ensure these tools are installed on your system:

- Ansible
- Docker
- HashiCorp Packer
- kubectl (configured for your Kubernetes cluster)
- Helm

## Build the Slurm container image

This will use Packer, Docker, and Ansible to build a docker image on your PC.

1. Edit `packer/build-slurm.pkr.hcl` and set variables.

    This must match a tag on <https://github.com/SchedMD/slurm/tags>.

    ```plaintext
    variable "slurm_version_tag" {
        default = "24-11-0-1"
    }
    ```

    Name your new image.

    ```plaintext
    variable "image_name" {
        default = "slurm"
        #default = "docker-registry.your.domain:5000/slurm"
    }
    ```

1. Use packer to build the image.

    ```shell
    cd packer

    packer init build-slurm.pkr.hcl

    packer build build-slurm.pkr.hcl
    ```

1. Update `helm/slurm-cluster/values.yaml` to set the image name, including registry and tag.

    It should be set in the default section:

    ```yaml
    defaults:
        image: docker-registry.your.domain:5000/slurm:24-11-0-1
    ```

    It can also be set individually on each component:

    ```yaml
    pods:
        slurmd:
            image: docker-registry.your.domain:5000/slurm:24-11-0-1-special
    ```

1. Finally, push this image to your Docker registry.

    ```shell
    docker push registry.your.domain:5000/slurm:24-11-0-1
    ```

## Set the MariaDB username and password

A password is needed by Slurm to communicate with the MariaDB instance that will be deployed.

### Option 1: Automatic

Do not include a MariaDB password in your settings. One will be generated automatically and the user set to `root`. After deployment this password can be retrieved from Kubernetes:

```shell
kubectl get secret slurm-cluster-mariadb-root -o jsonpath="{.data.password}" | base64 -d ; echo
```

### Option 2: secrets.yaml

Create `helm/secrets.yaml` and set your database username/pass.

```plaintext
mariadb:
    secret:
        username: "slurm"
        password: "your-actual-password-here"
```

### Using an exising database

When the MariaDB pod has a persistentVolume mounted at /var/lib/mysql, that volume may contain an existing database (for example, a previous deployment of Slurm). In that case, the existing database's password must be set in the yaml file.

## Configure storage

1. Edit `helm/slurm-cluster/values.yaml` and set parameters for persistentVolumes. Three of them are required:

    ```yaml
    volumes:
        mariadb:
            - name: mariadb-data
            mountPath: /var/lib/mysql
        munge:
            - name: munge-etc
            mountPath: /etc/munge
        slurmctld:
            - name: slurmctld-spool
            mountPath: /var/spool/slurmctld
    ```

    More volumes can be added at any mountPath. For example, to mount a shared filesystem into the slurmd nodes:

    ```yaml
    # NFS example
    - name: home
        mountPath: /home
        # Optional, defaults to Retain
        reclaimPolicy: Delete
        size: 10Gi
        storageClassName: local-ssd
        accessModes:
            - ReadWriteMany
        spec:
            nfs:
                server: aster.your.domain
                path: /apps/slurm-cluster/slurmd/home
    ```

1. Ensure the storage specified in your values.yaml allows access by the UID also specified.

    ```yaml
    defaults:
        securityContext:
            runAsUser: 980
            runAsGroup: 980
            fsGroup: 980
    ```

    ```shell
    STORAGE_PATH=/apps/slurm-cluster

    mkdir -p "${STORAGE_PATH}/slurmctld/spool"
    mkdir -p "${STORAGE_PATH}/mariadb/data"
    mkdir -p "${STORAGE_PATH}/munge/etc"
    sudo chown -R 980:980 "${STORAGE_PATH}"
    ```

## Install the Helm chart from source

1. Set the namespace (or use `-n YOUR-NAMESPACE` in every command).

    ```shell
    export HELM_NAMESPACE=YOUR-NAMESPACE

    kubectl config set-context --current --namespace=YOUR-NAMESPACE
    ```

1. Edit `helm/slurm-cluster/values.yaml` with your preferences then validate the helm chart values. This should create valid Kubernetes YAML. If the validate step shows an error, review your values.yaml and try again.

    _Note: Add `-f secrets.yaml` if you have a secrets file._

      ```shell
    helm template slurm-cluster helm/slurm-cluster/ > rendered-manifests.yaml
    ```

1. Update helm dependencies.

    ```shell
    cd helm/slurm-cluster
    helm dependency update
    cd ../
    ```

1. Deploy the Kubernetes resources.

    ```shell
    kubectl create namespace YOUR-NAMESPACE
    ```

    _Note: Add `-f secrets.yaml` if you have a secrets file._

    ```shell
    helm install slurm-cluster helm/slurm-cluster/
    ```

    The result should should be something like this:

    ```plaintext
    NAME: slurm-cluster
    LAST DEPLOYED: Sat Dec 28 15:51:42 2024
    NAMESPACE: YOUR-NAMESPACE
    STATUS: deployed
    REVISION: 1
    TEST SUITE: None
    NOTES:
    Thank you for installing slurm-cluster!

    Your Slurm cluster has been deployed with the following components:

    1. MariaDB database:
        Service: slurm-cluster-mariadb:3306

        To retrieve the MariaDB root password used during deployment, run:
            kubectl get secret -n YOUR-NAMESPACE slurm-cluster-mariadb-root -o jsonpath="{.data.password}" | base64 -d ; echo

    2. Slurm database daemon (slurmdbd):
        Service: slurm-cluster-slurmdbd:6819

    3. Slurm controller (slurmctld):
        Service: slurm-cluster-slurmctld:6817

    4. Slurm node watcher
        Monitors the Kubernetes event stream to add or remove slurmd nodes from the Slurm controller.

    5. Compute nodes (slurmd pods): 2

    To verify your installation:

    1. Check that all pods are running:
        kubectl get pods -n YOUR-NAMESPACE -l "app.kubernetes.io/instance=slurm-cluster"

    2. View component logs:
        kubectl logs -n YOUR-NAMESPACE -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=mariadb"
        kubectl logs -n YOUR-NAMESPACE -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmdbd"
        kubectl logs -n YOUR-NAMESPACE -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmctld"
        kubectl logs -n YOUR-NAMESPACE -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=node-watcher"
        kubectl logs -n YOUR-NAMESPACE -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmd"

    3. Check cluster status (from slurmctld pod):
        kubectl exec -n YOUR-NAMESPACE statefulset/slurm-cluster-slurmctld -- sinfo

    For more information about using Slurm, please refer to:
    https://slurm.schedmd.com/documentation.html
    ```
