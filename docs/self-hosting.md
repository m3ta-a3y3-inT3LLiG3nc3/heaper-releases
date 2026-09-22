# Self-host Heaper with Docker

This repository ships an all-in-one Docker Compose setup for Heaper using the image `ghcr.io/janlunge/heaper:latest`.

The checked-in configuration exposes Heaper on host port `3010`, stores all persistent data under `./heaper-data/`, and enables the image's internal PostgreSQL by default.

## What this setup includes

From `docker-compose.yml`:

- Image: `ghcr.io/janlunge/heaper:latest`
- Platform constraint: `linux/amd64`
- Published HTTP port: `3010:80`
- Default internal database mode: `ENABLE_INTERNAL_POSTGRES=true`
- Persistent host paths:
  - `./heaper-data/postgres`
  - `./heaper-data/data`
  - `./heaper-data/config`
  - `./heaper-data/thumbnails`
  - `./heaper-data/storage`
  - `./heaper-data/backups`

## Prerequisites

- Docker Engine and Docker Compose v2
- Enough disk space for application data and uploaded content
- Enough RAM for the container limit configured in Compose (`4g`)
- An x86_64/amd64 Docker host, or an ARM host that can run `linux/amd64` containers through emulation

If you plan to access Heaper from another machine, also make sure the host firewall allows inbound TCP traffic to port `3010` or to your reverse proxy.

## Directory setup

Work from the repository root:

```bash
cd /path/to/heaper-releases
cp .env.example .env
mkdir -p heaper-data/{postgres,data,config,thumbnails,storage,backups}
```

The directories above match the bind mounts in `docker-compose.yml`.

## Configure `.env` securely

This repository only uses the following environment variables:

| Variable | Required | Default in `.env.example` | Purpose |
| --- | --- | --- | --- |
| `HOSTNAME` | Yes | `localhost` | External hostname for browser/desktop access; keep `localhost` only for same-machine testing |
| `POSTGRES_USER` | Yes | `heaper` | PostgreSQL username |
| `POSTGRES_PASSWORD` | Yes | `change-me-please` | PostgreSQL password; replace before first start |
| `POSTGRES_DB` | Yes | `heaper` | PostgreSQL database name |
| `ENABLE_INTERNAL_POSTGRES` | Yes | `true` | Keeps the bundled database enabled |

Generate a strong database password before the first start:

```bash
openssl rand -base64 32
```

Then edit `.env` and replace `POSTGRES_PASSWORD` with the generated value.

Security notes:

- Do **not** commit `.env`.
- Keep `.env` readable only by administrators on the host.
- Leave the PostgreSQL port commented out unless you explicitly need external database access.

## Start Heaper

```bash
docker compose pull
docker compose up -d
```

For same-host testing, open [http://localhost:3010](http://localhost:3010).

For another machine on the network, use `http://YOUR-SERVER:3010` or your reverse-proxied HTTPS URL.

## Day-2 operations

### Check status

```bash
docker compose ps
docker inspect --format='{{.State.Health.Status}}' heaper
```

### Follow logs

```bash
docker compose logs -f heaper
```

### Health checks

```bash
curl http://localhost:3010/api
curl http://localhost:3010/sync/health
docker exec heaper pg_isready -h localhost -U heaper
```

If you changed `POSTGRES_USER`, use that value instead of `heaper` in the `pg_isready` command.

### Restart or stop

```bash
docker compose restart heaper
docker compose stop
```

### Start again after stopping

```bash
docker compose up -d
```

### Update to the newest image

```bash
docker compose pull
docker compose up -d
```

This preserves the data stored under `./heaper-data/`.

## Persistent data and backups

### What is stored where

| Host path | Container path | What it is for |
| --- | --- | --- |
| `./heaper-data/postgres` | `/var/lib/postgresql/data` | PostgreSQL data directory |
| `./heaper-data/data` | `/usr/src/app/data` | Application data |
| `./heaper-data/config` | `/usr/src/app/config` | Application configuration |
| `./heaper-data/thumbnails` | `/mnt/thumbnails` | Thumbnail cache/data |
| `./heaper-data/storage` | `/mnt/storage` | Stored user content |
| `./heaper-data/backups` | `/mnt/backups` | Backup files written by the container, if used |

### Recommended backup method

Back up the entire `heaper-data/` tree so the database, config, and stored content stay together.

```bash
docker compose stop
tar -czf heaper-backup-$(date +%F).tar.gz heaper-data
```

After the archive completes, restart the service:

```bash
docker compose up -d
```

### Restore from a filesystem backup

> Restoring overwrites the current instance data.

```bash
docker compose stop
mv heaper-data heaper-data.old
mkdir -p heaper-data
tar -xzf heaper-backup-YYYY-MM-DD.tar.gz

docker compose up -d
```

After you verify the restored instance, remove `heaper-data.old` if you no longer need it.

## Networking, firewall, reverse proxy, and TLS

### Required settings

- Publish port `3010` if clients connect directly to the Docker host.
- Allow inbound TCP traffic to the published port in the host firewall.
- Set `HOSTNAME` to the hostname users should actually use. Leave `localhost` only for same-machine testing.

### Example: direct access without a reverse proxy

Nothing else is required beyond the checked-in Compose file:

```text
http://10.0.0.20:3010
```

Use this only on a trusted local network or through a VPN.

### Example: reverse proxy with TLS

A reverse proxy is optional, but recommended for internet-facing use.

Example topology:

```text
https://heaper.example.com  ->  reverse proxy  ->  http://127.0.0.1:3010
```

When you use a reverse proxy:

- Present a valid TLS certificate to clients.
- Point the proxy to the host's port `3010`.
- Have desktop users connect to the public HTTPS hostname, not `http://container-name` and not an internal Docker IP.

### PostgreSQL exposure

The Compose file keeps port `5432` commented out. Leave it that way unless you have a specific administrative reason to expose PostgreSQL externally.

## Architecture and configuration notes

- The `heaper` service is a single published container with the name `heaper`.
- `ENABLE_INTERNAL_POSTGRES=true` means this setup is designed to run with the image's bundled PostgreSQL path.
- `platform: linux/amd64` is explicit. On ARM hosts, Docker must emulate amd64; that can increase startup time and resource usage.
- The container is configured with `restart: unless-stopped`, so it should come back after host reboots unless you stopped it manually.

## Connect the desktop app

See the full desktop guide in [desktop.md](desktop.md).

Short version:

1. Start and sign in to the desktop app.
2. Open **Settings → Heaps → Pull Heap**.
3. Enter either:
   - `http://YOUR-SERVER:3010` for direct access to the checked-in Compose setup, or
   - `https://heaper.example.com` when you have a reverse proxy with TLS.
4. Test browser access to `/api` and `/sync/health` first if the desktop app cannot connect.

## Troubleshooting

### Container does not stay up

```bash
docker compose ps
docker compose logs --tail=200 heaper
```

Common causes are a bad `.env` value, an invalid or unchanged `POSTGRES_PASSWORD`, or a host resource problem.

### Port `3010` is already in use

Another service is already bound to that port on the host. Stop the conflicting service or change the published host port in `docker-compose.yml` and update your client URLs to match.

### The app loads locally but not from another machine

Check all of the following:

- The host firewall allows the chosen port.
- The client can resolve the server hostname.
- You are using the host IP/hostname, not `localhost`, from remote devices.
- Your reverse proxy forwards to `http://HOST:3010` if you enabled one.

### ARM host issues

This Compose file is pinned to `linux/amd64`. If the host is ARM-based, verify that Docker's amd64 emulation support is available before treating the deployment as production-ready.

### Desktop app cannot attach to the server

From the desktop machine, run:

```bash
curl http://YOUR-SERVER:3010/api
curl http://YOUR-SERVER:3010/sync/health
```

If direct HTTP works but HTTPS does not, fix your reverse proxy or TLS certificate first.

## Stop, remove, or delete data

### Stop and remove the container only

```bash
docker compose down --remove-orphans
```

This removes the container and network but keeps `./heaper-data/` and `.env`.

### Permanently delete all local data

> Warning: this is irreversible.

```bash
docker compose down --remove-orphans
rm -rf heaper-data .env
```

Do this only when you intentionally want to destroy the local Heaper instance, database, uploads, thumbnails, config, and backups.

## Supported integration boundary

This repository documents the bundled Docker deployment and the desktop app connection to that deployment. For broader product integrations or features that are not represented in `docker-compose.yml`, `.env.example`, or the published desktop artifacts, use the official upstream docs.
