#!/bin/bash


# Error handling
set -euo pipefail
trap 'log "Error on line $LINENO"' ERR


# Logging setup
log() {
  echo "$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ") $*"
}


get_cpu_quota() {
  local cpu_quota
  local cpu_period

  # Try to read CPU quota and period from cgroups v2 first
  if [ -f /sys/fs/cgroup/cpu.max ]; then
    read cpu_quota cpu_period < /sys/fs/cgroup/cpu.max
  # Fall back to cgroups v1
  elif [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ] && [ -f /sys/fs/cgroup/cpu/cpu.cfs_period_us ]; then
    cpu_quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
    cpu_period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
  else
    echo "Unable to determine CPU quota" >&2
    return 1
  fi

  # If quota is -1 (unlimited), use the host's CPU count
  if [ "$cpu_quota" = "-1" ] || [ "$cpu_quota" = "max" ]; then
    nproc
    return
  fi

  # Calculate number of CPUs from quota
  echo $((cpu_quota / cpu_period))
}


setup_munge() {
  log "Preparing for munge daemon"

  for dir in "/run/munge" "/var/log/munge" "/etc/munge"; do
    mkdir -p "$dir"
    chown munge:munge "$dir"
  done

  log "Checking for munge key"
  if [[ -f /etc/munge/munge.key ]]; then
    log "/etc/munge/munge.key already exists"
  else
    log "Creating munge key at /etc/munge/munge.key"
    /usr/sbin/mungekey --verbose --create --keyfile=/etc/munge/munge.key
  fi
  chown munge:munge /etc/munge/munge.key
  chmod 400 /etc/munge/munge.key

  log "Starting munge daemon"
  sudo -u munge /usr/sbin/munged

  sleep 5
}


launch_slurmdbd() {
  log "Preparing for slurmdbd daemon"

  touch /var/log/slurmdbd.log
  chown slurm:slurm /var/log/slurmdbd.log

  touch /var/run/slurmdbd.pid
  chown slurm:slurm /var/run/slurmdbd.pid

  chown slurm:slurm /etc/slurm/slurmdbd.conf
  chmod 600 /etc/slurm/slurmdbd.conf

  log "Waiting for mariadb to become available"

  until nc -z mariadb 3306; do
    sleep 5
  done

  log "mariadb is up - proceeding with startup"

  log "Starting slurmdbd daemon"
  exec sudo -u slurm /usr/sbin/slurmdbd -D -v
}


launch_slurmctld() {
  log "Preparing for slurmctld daemon"

  touch /var/log/slurmctld.log
  chown slurm:slurm /var/log/slurmctld.log

  touch /var/run/slurmctld.pid
  chown slurm:slurm /var/run/slurmctld.pid

  mkdir -p /var/spool/slurmctld
  chown slurm:slurm /var/spool/slurmctld

  log "Waiting for slurmdbd to become available"

  until nc -z slurmdbd 6819; do
    sleep 5
  done

  log "slurmdbd is up - proceeding with startup"

  log "Starting slurmctld daemon"
  exec sudo -u slurm /usr/sbin/slurmctld -D -v
}


launch_slurmd() {
  log "Preparing for slurmd daemon"

  touch /var/log/slurmd.log
  chown slurm:slurm /var/log/slurmd.log

  touch /var/run/slurmd.pid
  chown slurm:slurm /var/run/slurmd.pid

  mkdir -p /var/spool/slurmd
  chown slurm:slurm /var/spool/slurmd

  log "Waiting for slurmctld to become available"

  until nc -z slurmctld 6817; do
    sleep 5
  done

  log "slurmctld is up - proceeding with startup"   

  log "Staring dbus"
  mkdir -p /run/dbus
  chown messagebus:messagebus /run/dbus
  chmod 755 /run/dbus
  dbus-daemon --system --fork --nopidfile

  cpu_count=$(get_cpu_quota)

  # Get memory limit in MB
  if [ -f /sys/fs/cgroup/memory.max ]; then
    # cgroups v2
    memory=$(( $(cat /sys/fs/cgroup/memory.max) / 1024 / 1024 ))
  elif [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
    # cgroups v1
    memory=$(( $(cat /sys/fs/cgroup/memory/memory.limit_in_bytes) / 1024 / 1024 ))
  else
    # Fallback to total system memory
    memory=$(( $(grep MemTotal /proc/meminfo | awk '{print $2}') / 1024 ))
  fi

  cat <<EOF > /etc/slurm/cgroup.conf
IgnoreSystemd=yes
CgroupPlugin=disabled
EOF

  log "Starting slurmd daemon"
  exec sudo -u slurm /usr/sbin/slurmd -D -Z -f /etc/slurm/slurm.conf --conf "CPUs=$cpu_count RealMemory=$memory"
}


# Main script execution
log "Starting entrypoint script"


# Determine which daemon to launch based on the first argument
case "${1:-}" in
  "launch_slurmdbd")
    setup_munge
    launch_slurmdbd
    ;;
  "launch_slurmctld")
    setup_munge
    launch_slurmctld
    ;;
  "launch_slurmd")
    setup_munge
    launch_slurmd
    ;;
  *)
    log "Usage: $0 {launch_slurmdbd|launch_slurmctld|launch_slurmd}"
    exit 1
    ;;
esac
