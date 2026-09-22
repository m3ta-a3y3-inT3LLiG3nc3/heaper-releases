#!/usr/bin/env bash
# Cloud Agent environment start: bring up the Docker daemon and the Heaper
# all-in-one stack on every boot. Idempotent and tolerant of restarts.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# 1. Start dockerd if it is not already running. systemd is not the init in
#    this VM, so the daemon is launched directly and detached with setsid.
if ! sudo docker info >/dev/null 2>&1; then
  echo "Starting dockerd..."
  sudo rm -f /var/run/docker.pid
  sudo bash -c 'setsid dockerd >/var/log/dockerd.log 2>&1 < /dev/null &'
  for _ in $(seq 1 30); do
    if sudo docker info >/dev/null 2>&1; then break; fi
    sleep 1
  done
fi

if ! sudo docker info >/dev/null 2>&1; then
  echo "dockerd failed to start; last log lines:" >&2
  sudo tail -n 20 /var/log/dockerd.log >&2 || true
  exit 1
fi

# Allow the agent to use the docker CLI without sudo for the rest of the session.
sudo chmod 666 /var/run/docker.sock || true

# 2. Bring up the Heaper all-in-one container (idempotent reconcile).
docker compose up -d

# 3. Wait for the container's built-in health check to pass.
echo "Waiting for Heaper to become healthy..."
for _ in $(seq 1 60); do
  status="$(docker inspect --format='{{.State.Health.Status}}' heaper 2>/dev/null || echo starting)"
  if [ "$status" = "healthy" ]; then
    echo "Heaper is healthy"
    break
  fi
  sleep 3
done

docker inspect --format='{{.State.Health.Status}}' heaper || true
echo "start.sh complete - Heaper available on http://localhost:3010"
