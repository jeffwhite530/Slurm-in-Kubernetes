# Verifying the Deployment

1. Verify the helm release status.

    ```shell
    helm ls
    ```

    ```plaintext
    NAME           NAMESPACE      REVISION  UPDATED     STATUS              CHART  APP  VERSION
    slurm-cluster  slurm-cluster  2         2024-12-22  14:23:07.923440676  -0500  EST  deployed  slurm-cluster-0.1.024.11.0.1
    ```

1. Verify the resources launched.

    1. Did the pods start and are they ready?

        ```shell
        kubectl get pods -l "app.kubernetes.io/instance=slurm-cluster"
        ```

        ```plaintext
        NAME                                         READY  STATUS   RESTARTS  AGE
        slurm-cluster-mariadb-0                      1/1    Running  0         13m
        slurm-cluster-node-watcher-0                 1/1    Running  0         13m
        slurm-cluster-slurmctld-0                    1/1    Running  0         13m
        slurm-cluster-slurmd-77f8554695-wjmgr        1/1    Running  0         13m
        slurm-cluster-slurmdbd-0                     1/1    Running  0         13m
        ```

    1. Did MariaDB launch successfully?

        ```shell
        kubectl logs -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=mariadb" --tail=-1
        ```

        ```plaintext
        2024-12-22 19:16:40+00:00 [Note] [Entrypoint]: Entrypoint script for MariaDB Server 11.6.2 started.
        2024-12-22 19:16:40+00:00 [Note] [Entrypoint]: MariaDB upgrade not required
        2024-12-22 19:16:40 0 [Note] Starting MariaDB 11.6.2-MariaDB source revision d8dad8c3b54cd09fefce7bc3b9749f427eed9709 server_uid ECAXpVBJpbtJNmAVANHBFmfORe4= as process 1
        2024-12-22 19:16:40 0 [Note] InnoDB: Compressed tables use zlib 1.2.11
        2024-12-22 19:16:40 0 [Note] InnoDB: Number of transaction pools: 1
        2024-12-22 19:16:40 0 [Note] InnoDB: Using crc32 + pclmulqdq instructions
        2024-12-22 19:16:40 0 [Note] mariadbd: O_TMPFILE is not supported on /tmp (disabling future attempts)
        2024-12-22 19:16:40 0 [Note] InnoDB: Using liburing
        2024-12-22 19:16:40 0 [Note] InnoDB: Initializing buffer pool, total size = 4.000GiB, chunk size = 64.000MiB
        2024-12-22 19:16:40 0 [Note] InnoDB: Completed initialization of buffer pool
        2024-12-22 19:16:40 0 [Note] InnoDB: File system buffers for log disabled (block size=512 bytes)
        2024-12-22 19:16:40 0 [Note] InnoDB: End of log at LSN=2547714
        2024-12-22 19:16:40 0 [Note] InnoDB: Opened 3 undo tablespaces
        2024-12-22 19:16:40 0 [Note] InnoDB: 128 rollback segments in 3 undo tablespaces are active.
        2024-12-22 19:16:40 0 [Note] InnoDB: Setting file './ibtmp1' size to 12.000MiB. Physically writing the file full; Please wait ...
        2024-12-22 19:16:40 0 [Note] InnoDB: File './ibtmp1' size is now 12.000MiB.
        2024-12-22 19:16:40 0 [Note] InnoDB: log sequence number 2547714; transaction id 5438
        2024-12-22 19:16:40 0 [Note] Plugin 'FEEDBACK' is disabled.
        2024-12-22 19:16:40 0 [Note] InnoDB: Loading buffer pool(s) from /var/lib/mysql/ib_buffer_pool
        2024-12-22 19:16:40 0 [Note] Plugin 'wsrep-provider' is disabled.
        2024-12-22 19:16:40 0 [Note] InnoDB: Buffer pool(s) load completed at 241222 19:16:40
        2024-12-22 19:16:41 0 [Note] Server socket created on IP: '0.0.0.0'.
        2024-12-22 19:16:41 0 [Note] Server socket created on IP: '::'.
        2024-12-22 19:16:41 0 [Note] mariadbd: Event Scheduler: Loaded 0 events
        2024-12-22 19:16:41 0 [Note] mariadbd: ready for connections.
        Version: '11.6.2-MariaDB'  socket: '/run/mariadb/mariadb.sock'  port: 3306  MariaDB Server
        ```

    1. Did slurmdbd launch successfully?

        ```shell
        kubectl logs -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmdbd" --tail=-1
        ```

        ```plaintext
        Defaulted container "slurmdbd" out of: slurmdbd, copy-slurmdbd-conf (init)
        2024-12-22T19:16:37.290Z Starting entrypoint script
        2024-12-22T19:16:37.291Z Preparing for munge daemon
        2024-12-22T19:16:37.301Z Checking for munge key
        2024-12-22T19:16:37.302Z Munge key already exists at /etc/munge/munge.key
        2024-12-22T19:16:37.304Z Starting munge daemon
        2024-12-22T19:16:38.307Z Preparing for slurmdbd daemon
        2024-12-22T19:16:38.313Z Waiting for mariadb to become available at slurm-cluster-mariadb-0
        2024-12-22T19:16:39.341Z Attempting to connect to slurm-cluster-mariadb-0:3306...
        2024-12-22T19:16:45.357Z Attempting to connect to slurm-cluster-mariadb-0:3306...
        2024-12-22T19:16:51.377Z Attempting to connect to slurm-cluster-mariadb-0:3306...
        2024-12-22T19:16:57.389Z Attempting to connect to slurm-cluster-mariadb-0:3306...
        2024-12-22T19:17:03.409Z Attempting to connect to slurm-cluster-mariadb-0:3306...
        2024-12-22T19:17:09.425Z Attempting to connect to slurm-cluster-mariadb-0:3306...
        2024-12-22T19:17:14.430Z mariadb is up at slurm-cluster-mariadb-0 - proceeding with startup
        2024-12-22T19:17:14.431Z Starting slurmdbd daemon
        slurmdbd: accounting_storage/as_mysql: _check_mysql_concat_is_sane: MySQL server version is: 11.6.2-MariaDB
        slurmdbd: accounting_storage/as_mysql: init: Accounting storage MYSQL plugin loaded
        slurmdbd: slurmdbd version 24.11.0 started
        ```

    1. Did slurmctld start successfully?

        ```shell
        kubectl logs -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmctld" --tail=-1
        ```

        ```plaintext
        2024-12-22T19:16:43.399Z Starting entrypoint script
        2024-12-22T19:16:43.400Z Preparing for munge daemon
        2024-12-22T19:16:43.410Z Checking for munge key
        2024-12-22T19:16:43.412Z Munge key already exists at /etc/munge/munge.key
        2024-12-22T19:16:43.413Z Starting munge daemon
        2024-12-22T19:16:44.416Z Preparing for slurmctld daemon
        2024-12-22T19:16:44.421Z Waiting for slurmdbd to become available at slurm-cluster-slurmdbd-0
        2024-12-22T19:16:45.453Z Attempting to connect to slurm-cluster-slurmdbd-0:6819...
        2024-12-22T19:16:51.469Z Attempting to connect to slurm-cluster-slurmdbd-0:6819...
        2024-12-22T19:17:26.555Z slurmdbd is up at slurm-cluster-slurmdbd-0 - proceeding with startup
        2024-12-22T19:17:26.556Z Starting slurmctld daemon
        slurmctld: slurmctld version 24.11.0 started on cluster slurm-cluster(2175)
        slurmctld: cred/munge: init: Munge credential signature plugin loaded
        slurmctld: select/linear: init: Linear node selection plugin loaded with argument 20
        slurmctld: select/cons_tres: init: select/cons_tres loaded
        slurmctld: accounting_storage/slurmdbd: init: Accounting storage SLURMDBD plugin loaded
        slurmctld: accounting_storage/slurmdbd: _load_dbd_state: recovered 0 pending RPCs
        slurmctld: accounting_storage/slurmdbd: clusteracct_storage_p_register_ctld: Registering slurmctld at port 6817 with slurmdbd
        slurmctld: _read_slurm_cgroup_conf: No cgroup.conf file (/etc/slurm/cgroup.conf), using defaults
        slurmctld: No memory enforcing mechanism configured.
        slurmctld: topology/default: init: topology Default plugin loaded
        slurmctld: sched: Backfill scheduler plugin loaded
        slurmctld: Recovered state of 1 nodes
        slurmctld: Recovered information about 0 jobs
        slurmctld: select/cons_tres: part_data_create_array: select/cons_tres: preparing for 1 partitions
        slurmctld: Recovered state of 0 reservations
        slurmctld: State of 0 triggers recovered
        slurmctld: read_slurm_conf: backup_controller not specified
        slurmctld: select/cons_tres: select_p_reconfigure: select/cons_tres: reconfigure
        slurmctld: select/cons_tres: part_data_create_array: select/cons_tres: preparing for 1 partitions
        slurmctld: Running as primary controller
        ```

    1. Did a slurmd instance start successfully?

        ```shell
        kubectl logs -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmd" --tail=-1
        ```

        ```plaintext
        2024-12-22T19:18:02.574Z Starting entrypoint script
        2024-12-22T19:18:02.575Z Preparing for munge daemon
        2024-12-22T19:18:02.585Z Checking for munge key
        2024-12-22T19:18:02.586Z Munge key already exists at /etc/munge/munge.key
        2024-12-22T19:18:02.588Z Starting munge daemon
        2024-12-22T19:18:03.591Z Preparing for slurmd daemon
        2024-12-22T19:18:03.596Z Waiting for slurmctld to become available at slurm-cluster-slurmctld-0
        2024-12-22T19:18:03.599Z slurmctld is up at slurm-cluster-slurmctld-0 - proceeding with startup
        2024-12-22T19:18:03.606Z Getting memory amount from cgroups v2
        4096
        2024-12-22T19:18:03.609Z Starting slurmd daemon
        slurmd: warning: Running with local config file despite slurmctld having been setup for configless operation
        slurmd: slurmd version 24.11.0 started
        slurmd: slurmd started on Sun, 22 Dec 2024 19:18:03 +0000
        slurmd: CPUs=1 Boards=1 Sockets=1 Cores=1 Threads=1 Memory=128717 TmpDisk=180686 Uptime=80365 CPUSpecList=(null) FeaturesAvail=(null) FeaturesActive=(null)
        ```

    1. Did the node watcher start successfully?

        ```shell
        kubectl logs -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=node-watcher" --tail=-1
        ```

        ```plaintext
        2024-12-22T19:16:34.778Z Starting entrypoint script
        2024-12-22T19:16:34.779Z Preparing for munge daemon
        2024-12-22T19:16:34.789Z Checking for munge key
        2024-12-22T19:16:34.790Z Munge key already exists at /etc/munge/munge.key
        2024-12-22T19:16:34.792Z Starting munge daemon
        2024-12-22T19:16:35.873Z Preparing for slurm-node-watcher daemon
        2024-12-22T19:16:35.876Z Waiting for slurmctld to become available at slurm-cluster-slurmctld-0
        2024-12-22T19:16:36.909Z Attempting to connect to slurm-cluster-slurmctld-0:6817...
        2024-12-22T19:16:42.925Z Attempting to connect to slurm-cluster-slurmctld-0:6817...
        2024-12-22T19:17:36.059Z slurmctld is up at slurm-cluster-slurmctld-0 - proceeding with startup
        2024-12-22T19:17:36.061Z Starting slurm-node-watcher daemon
        2024-12-22 19:17:37,483 - INFO - Starting Slurm node controller
        2024-12-22 19:17:37,484 - INFO - Performing initial sync...
        2024-12-22 19:17:37,598 - INFO - Removed node slurm-cluster-slurmd-77f8554695-p7s2h
        2024-12-22 19:17:37,598 - INFO - Initial sync complete
        2024-12-22 19:17:37,598 - INFO - Starting to watch for pod events...
        ```
