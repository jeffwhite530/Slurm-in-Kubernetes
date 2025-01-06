# Launching a Test Job

This shows how to launch test jobs into Slurm after the cluster has deployed.

1. Check the Slurm cluster status.

    1. List the partitions.

        ```shell
        pod_name=$(kubectl get pods -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmctld" -o jsonpath='{.items[0].metadata.name}')
        ```

        ```shell
        kubectl exec -it $pod_name -- sinfo
        ```

        ```plaintext
        Defaulted container "slurmctld" out of: slurmctld, copy-slurmdbd-conf (init), copy-slurm-conf (init)
        PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
        main*          up    infinite        1    idle slurm-cluster-slurmd-77f8554695-wjmgr
        ```

    1. List the Slurm nodes.

        ```shell
        kubectl exec -it $pod_name -- scontrol show nodes
        ```

        ```plaintext
        Defaulted container "slurmctld" out of: slurmctld, copy-slurmdbd-conf (init), copy-slurm-conf (init)
        NodeName=slurm-cluster-slurmd-77f8554695-wjmgr Arch=x86_64 CoresPerSocket=1
            CPUAlloc=0 CPUEfctv=1 CPUTot=1 CPULoad=1.49
            AvailableFeatures=(null)
            ActiveFeatures=(null)
            Gres=(null)
            NodeAddr=10.10.1.231 NodeHostName=slurm-cluster-slurmd-77f8554695-wjmgr Version=24.11.0
            OS=Linux 6.1.0-28-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.119-1 (2024-11-22)
            RealMemory=4096 AllocMem=0 FreeMem=51734 Sockets=1 Boards=1
            State=IDLE+DYNAMIC_NORM ThreadsPerCore=1 TmpDisk=0 Weight=1 Owner=N/A MCS_label=N/A
            Partitions=main
            BootTime=2024-12-21T20:58:39 SlurmdStartTime=2024-12-22T19:18:03
            LastBusyTime=2024-12-22T19:17:37 ResumeAfterTime=None
            CfgTRES=cpu=1,mem=4G,billing=1
            AllocTRES=
            CurrentWatts=0 AveWatts=0
        ```

1. Launch a test hello-world Slurm job.

    1. Copy a job script into a container.

        ```shell
        pod_name=$(kubectl get pods -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmctld" -o jsonpath='{.items[0].metadata.name}')
        ```

        ```shell
        kubectl cp scripts/hello-world-job.sh "${pod_name}":/tmp/
        ```

    1. Submit the job.

        ```shell
        kubectl exec -it "${pod_name}" -- sbatch /tmp/hello-world-job.sh
        ```

        ```plaintext
        Defaulted container "slurmctld" out of: slurmctld, copy-slurmdbd-conf (init), copy-slurm-conf (init)
        Submitted batch job 1
        ```

    1. Check the job status.

        ```shell
        kubectl exec -it "${pod_name}" -- sacct --format=JobID,JobName,State,NodeList%25,StdOut,StdErr
        ```

        ```plaintext
        Defaulted container "slurmctld" out of: slurmctld, copy-slurmdbd-conf (init), copy-slurm-conf (init)
        JobID              JobName        State                        NodeList                    StdOut                    StdErr
        ------------ ---------- ---------- ------------------------- -------------------- --------------------
        1                 hello-wo+  COMPLETED slurm-cluster-slurmd-77f+        /tmp/job-%j.out        /tmp/job-%j.err
        1.batch              batch  COMPLETED slurm-cluster-slurmd-77f+
        ```

    1. Check the job's output file. Use the node (container name the job ran in) and log file from sacct above.

        ```shell
        pod_name=$(kubectl get pods -l "app.kubernetes.io/instance=slurm-cluster,app.kubernetes.io/component=slurmd" -o jsonpath='{.items[0].metadata.name}')
        ```

        ```shell
        kubectl exec -it "${pod_name}" -- cat /tmp/job-1.out
        ```

        ```plaintext
        Starting job at Sun Dec 22 23:31:33 UTC 2024
        Running on hostname: slurm-cluster-slurmd-77f8554695-wjmgr
        Job ID: 1
        Job name: hello-world
        Allocated nodes: slurm-cluster-slurmd-77f8554695-wjmgr
        Number of CPUs allocated: 1
        Job completed at Sun Dec 22 23:31:33 UTC 2024
        ```
