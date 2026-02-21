# Yet Another Radarr and Sonarr Guides

This repo has a few different setup paths depending on how you want to run your ARR stack.

All guides assume you're comfortable with basic Linux CLI stuff.

## Option 1: Full 2026 Docker Compose Stack (Recommended)

Guide: [Docker-Compose_Setup.md](Docker-Compose_Setup.md)

Best for:

- People who want a modern ARR stack in Docker
- VPN-routed download traffic using WireGuard
- A full ecosystem setup, not just Radarr/Sonarr alone

Services covered:

- `wireguard`, `deluge`
- `radarr`, `sonarr`, `bazarr`, `readarr`
- `4K_radarr`, `4K_bazarr`
- `prowlarr`, `overseerr`
- `profilarr`, `huntarr`, `cleanuparr`, `whisper-subgen`, `agregarr`

## Option 2: Dockerless / Native Service Setup (Legacy)

Guide: [Dockerless_Setup.md](Dockerless_Setup.md)

Best for:

- People intentionally running services directly on the host (no Docker)
- Older installs/migrations

Note: this guide is older and pre-container.
