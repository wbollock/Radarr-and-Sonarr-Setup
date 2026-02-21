# Yet Another Radarr and Sonarr Guide - 2026 Docker Compose Edition

After a few years of running and breaking this stack in different ways, this is the cleaned-up version for a modern Docker setup. It is mostly set-and-forget but I do want to migrate to Nomad soon.

This guide is for people who want one compose stack for the ARR ecosystem, with torrent traffic going through WireGuard (Mullvad).

## What we're building

- One `wireguard` container handles network egress and published ports
- ARR and related services use `network_mode: service:wireguard` 
- Configs live in per-service folders
- Media/download paths are shared across services with a consistent mount

## Services in this stack

This guide covers all of these services:

- `wireguard`
- `deluge`
- `radarr`
- `sonarr`
- `bazarr`
- `4K_radarr`
- `4K_bazarr`
- `prowlarr`
- `overseerr`
- `profilarr`
- `huntarr`
- `cleanuparr`
- `readarr`
- `whisper-subgen`
- `agregarr`

Some are optional like whisper-subgen. Others you really must have in some form like deluge.

## Before you start

You need:

- Linux host with Docker + Compose plugin (`docker compose`). This might work on Mac too.
- A VPN provider/config for WireGuard (example in this repo uses Mullvad configs)
- A plan for:
  - app config path (example: `/opt/<service>`), where to store configs for applications.
  - media/download path (example: `/mnt/storage`), this can be as large or small as you want!

Quick checks for `docker`:

```bash
docker --version
docker compose version
```

## Directory layout (example)

Use any layout you like, but keep it consistent.

Example:

```text
~/docker/pvr/
  docker-compose.yaml
  wireguard-config/
  mullvad/
```

It is easier to just keep app configs next to `docker-compose.yaml` and run everything as one normal user (`PUID`/`PGID`), for example with `./radarr`, `./sonarr`, and similar folders. Creating separate `/opt/...` directories and separate service users is optional and mostly useful for stricter isolation/hardening. Start simple with one user and local folders, then split things out later only if you want to. Easy enough to script it out. In the past I created specific users for services like radarr/sonnar but that may be overkill.

## Example docker-compose.yaml (2026 style)

This is it! You can pretty much just copy this into your server as `docker-compose.yaml`, and run `sudo docker compose up -d`. Check logs for any errors. Manual intervention will be needed for mullvad config (or your chosen VPN provider with wireguard) and some application settings like the GUI of Radarr/Sonnar/Deluge.

I also recommend pinning images and not defaulting to `latest` for stability moreso than anything.

```yaml
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:1.0.20250521
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - ./wireguard-config:/config
      - ./mullvad:/mullvad:ro
      - /lib/modules:/lib/modules:ro
    ports:
      - 8989:8989 # sonarr
      - 7878:7878 # radarr
      - 7979:7979 # 4k radarr
      - 6767:6767 # bazarr
      - 6969:6969 # 4k bazarr
      - 8112:8112 # deluge web
      - 9696:9696 # prowlarr
      - 5055:5055 # overseerr
      - 6868:6868 # profilarr
      - 9705:9705 # huntarr
      - 11011:11011 # cleanuparr
      - 8787:8787 # readarr
      - 8788:8788 # reading glasses
      - 7171:7171 # agregarr
      - 1080:1080 # socks5
      - 6881:6881
      - 6881:6881/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
      - net.ipv6.conf.all.disable_ipv6=0
    restart: always

  deluge:
    image: linuxserver/deluge:2.2.0
    container_name: deluge
    network_mode: service:wireguard
    environment:
      - PUID=1006
      - PGID=1002
      - TZ=America/New_York
      - UMASK=000
      - DELUGE_LOGLEVEL=error
    volumes:
      - /opt/deluge:/config
      - /mnt/storage:/data
    restart: always

  radarr:
    image: linuxserver/radarr:6.1.0-nightly
    container_name: radarr
    network_mode: service:wireguard
    environment:
      - PUID=1003
      - PGID=1002
      - TZ=America/New_York
    volumes:
      - /opt/radarr:/config
      - /mnt/storage:/data
    restart: always

  sonarr:
    image: linuxserver/sonarr:4.0.16
    container_name: sonarr
    network_mode: service:wireguard
    environment:
      - PUID=1004
      - PGID=1002
      - TZ=America/New_York
    volumes:
      - /opt/sonarr:/config
      - /mnt/storage:/data
    restart: always

  bazarr:
    image: linuxserver/bazarr:1.5.4-development
    container_name: bazarr
    network_mode: service:wireguard
    environment:
      - PUID=1007
      - PGID=1002
      - TZ=America/New_York
      - UMASK_SET=022
    volumes:
      - /opt/bazarr:/config
      - /mnt/storage:/data
    restart: always

  4K_radarr:
    image: linuxserver/radarr:6.1.0-nightly
    container_name: 4K_radarr
    network_mode: service:wireguard
    environment:
      - PUID=1008
      - PGID=1002
      - TZ=America/New_York
    volumes:
      - /opt/4K_radarr:/config
      - /mnt/storage:/data
    restart: always

  4K_bazarr:
    image: linuxserver/bazarr:1.5.4-development
    container_name: 4K_bazarr
    network_mode: service:wireguard
    environment:
      - PUID=1009
      - PGID=1002
      - TZ=America/New_York
      - UMASK_SET=022
    volumes:
      - /opt/4K_bazarr:/config
      - /mnt/storage:/data
    restart: always

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:1.29.2-nightly
    container_name: prowlarr
    network_mode: service:wireguard
    environment:
      - PUID=1010
      - PGID=1002
      - TZ=America/New_York
    volumes:
      - /opt/prowlarr:/config
    restart: always

  overseerr:
    image: lscr.io/linuxserver/overseerr:1.33.2
    container_name: overseerr
    network_mode: service:wireguard
    environment:
      - PUID=1011
      - PGID=1002
      - TZ=America/New_York
    volumes:
      - /opt/overseerr:/config
    restart: unless-stopped

  profilarr:
    image: santiagosayshey/profilarr:v1.1.3
    container_name: profilarr
    network_mode: service:wireguard
    environment:
      - PUID=1014
      - PGID=1002
      - TZ=America/New_York
    volumes:
      - /opt/profilarr:/config
    restart: unless-stopped

  huntarr:
    image: huntarr/huntarr:159f6bf989415ae30c94ab08b2543d8664381f9d
    container_name: huntarr
    network_mode: service:wireguard
    environment:
      - TZ=America/New_York
    volumes:
      - /opt/huntarr:/config
    restart: always

  cleanuparr:
    image: ghcr.io/cleanuparr/cleanuparr:2.4.5
    container_name: cleanuparr
    network_mode: service:wireguard
    environment:
      - PUID=1015
      - PGID=1002
      - TZ=America/New_York
      - PORT=11011
      - BASE_PATH=
      - UMASK=022
    volumes:
      - /opt/cleanuparr:/config
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11011/health"]
      interval: 30s
      timeout: 10s
      start_period: 30s
      retries: 3
    restart: unless-stopped

  readarr:
    image: linuxserver/readarr:0.4.19-nightly
    container_name: readarr
    network_mode: service:wireguard
    environment:
      - PUID=1016
      - PGID=1002
      - TZ=America/New_York
    volumes:
      - /opt/readarr:/config
      - /mnt/storage:/data
    restart: always

  whisper-subgen:
    image: mccloud/subgen:latest
    container_name: whisper-subgen
    network_mode: service:wireguard
    environment:
      - PUID=1017
      - PGID=1002
      - TZ=America/New_York
      - SUBGEN_WHISPER_MODEL=base
      - SUBGEN_WHISPER_DEVICE=cpu
      - WHISPER_THREADS=1
      - OMP_NUM_THREADS=1
    volumes:
      - /opt/whisper-subgen:/config
      - /mnt/storage:/data
    restart: unless-stopped

  agregarr:
    image: agregarr/agregarr:2.0.0
    container_name: agregarr
    network_mode: service:wireguard
    volumes:
      - /opt/agregarr:/app/config
    restart: unless-stopped
```

## Bring it up

From the directory with `docker-compose.yaml`:

```bash
docker compose up -d
```

Check status:

```bash
docker compose ps
docker compose logs
# specific logs
docker compose logs --tail=200 radarr sonarr deluge prowlarr
```

## Service URLs

Use your server IP + port:

- Sonarr: `:8989`
- Radarr: `:7878`
- 4K Radarr: `:7979`
- Deluge: `:8112`
- Prowlarr: `:9696`
- Bazarr: `:6767`
- 4K Bazarr: `:6969`
- Overseerr: `:5055`
- Profilarr: `:6868`
- Huntarr: `:9705`
- Cleanuparr: `:11011`
- Readarr: `:8787`
- Agregarr: `:7171`

I use nginx proxy manager to create nice subdomains for everything. It only runs locally on a home LAN. Do not expose these services publiclly!!

## Important path note (this gets people every time)

Inside these containers, media is mounted at `/data`.

So in Radarr/Sonarr/Readarr/Deluge settings, use paths under `/data/...`, not host paths that only exist outside the container.

Example:

- Host path: `/mnt/storage/media/movies`
- Container path: `/data/media/movies`

## Troubleshooting

If apps are "up" but can't reach indexers/download client, check `wireguard` first.

```bash
docker compose logs --tail=300 wireguard
docker exec -it wireguard sh -c 'ip addr; wg show'
```

If UI is unreachable, confirm:

- Port is published on `wireguard`
- Firewall allows that port
- Service actually started (`docker compose ps`)

## Useful commands

```bash
# stop everything
docker compose stop

# start everything
docker compose start

# restart one app
docker compose restart radarr

# restart stack
docker compose restart

# recreate after changes
docker compose up -d --force-recreate

# follow logs
docker compose logs -f
```

## Backup priorities

At minimum, back up:

- Your `docker-compose.yaml`
- WireGuard config directory
- VPN config directory (if local)
- Service config directories (for example `/opt/*`)

Media data is separate from app config. Back it up on its own schedule.
