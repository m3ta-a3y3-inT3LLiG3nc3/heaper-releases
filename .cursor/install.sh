#!/usr/bin/env bash
# Cloud Agent environment install: prepare Docker + local config for the
# Heaper all-in-one self-host stack. Idempotent and safe to re-run.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

export DEBIAN_FRONTEND=noninteractive

# 1. Install Docker Engine, the Compose plugin, and the dependencies needed to
#    run Docker inside the nested-container Cloud Agent VM.
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker Engine..."
  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update -qq
  # --force-confold keeps the existing /etc/fuse.conf and avoids an
  # interactive dpkg conffile prompt that would otherwise hang the install.
  sudo apt-get install -y -qq -o Dpkg::Options::="--force-confold" \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    fuse-overlayfs fuse3 iptables uidmap
else
  echo "Docker already installed: $(docker --version)"
fi

# 2. The VM has no overlay2 kernel module, so tell dockerd to use fuse-overlayfs.
sudo mkdir -p /etc/docker
if [ ! -f /etc/docker/daemon.json ]; then
  echo '{
  "storage-driver": "fuse-overlayfs"
}' | sudo tee /etc/docker/daemon.json >/dev/null
fi

# 3. Create a local .env (dev-only Postgres password) from the template.
#    .env is gitignored; the internal Postgres is not exposed outside the container.
if [ ! -f .env ]; then
  cp .env.example .env
  sed -i 's/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=heaper-dev-local-password/' .env
  echo "Created .env with a development POSTGRES_PASSWORD"
fi

echo "install.sh complete"
