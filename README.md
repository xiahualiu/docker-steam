# Docker Steam

Minimal Docker setup for running a dedicated server via Steam.

## Quick start

1. Ensure Docker and Docker Compose are installed.
2. From the repo root, run:

```bash
docker compose up
```

* Server files live in the `game/` directory.
* Game save files live in the `save/` directory.

Edit `compose.yaml` or `entrypoint.sh` to change configuration.
