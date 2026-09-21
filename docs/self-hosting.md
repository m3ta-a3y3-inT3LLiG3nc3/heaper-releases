# Self-host Heaper with Docker

This repo ships the official all-in-one compose from [Heaper self-hosting](https://docs.heaper.de/docs/self-hosting) and the [all-in-one setup](https://docs.heaper.de/docs/self-hosting/all-in-one). The image is `ghcr.io/janlunge/heaper:latest`.

## Prerequisites

- Docker and Docker Compose
- A domain is recommended if you put TLS in front with Caddy or nginx (see the official docs)

## Start

```bash
cp .env.example .env
# Set POSTGRES_PASSWORD to a strong unique value. Do not commit .env.
docker compose up -d
```

Open [http://localhost:3010](http://localhost:3010).

## Health checks

From the [self-hosting docs](https://docs.heaper.de/docs/self-hosting):

```bash
docker inspect --format='{{.State.Health.Status}}' heaper
curl http://localhost:3010/api
curl http://localhost:3010/sync/health
docker exec heaper pg_isready -h localhost -U heaper
```

## Connect the desktop app

Log in to your cloud account, then add the server under **Settings → Heaps → Pull Heap** with the IP or hostname. For TLS, put a reverse proxy with a valid certificate in front of Heaper.

## Updates

```bash
docker compose pull
docker compose up -d
```

Nightly images (`ghcr.io/janlunge/heaper:nightly`) are an opt-in testing channel. Keep `:latest` for stable installs.

## Backups

Mounting `/mnt/backups` (already in this compose file) enables automated daily database backups. Optional backup environment variables and restore commands are documented in the [self-hosting guide](https://docs.heaper.de/docs/self-hosting).
