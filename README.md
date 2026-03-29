# racadm-docker

Containerized RACADM client for managing Dell PowerEdge servers via iDRAC7.

## Prerequisites

Download the **Dell iDRAC Tools for Linux** tarball and place it in the project root:

- [Dell-iDRACTools-Web-LX-11.4.0.0-1435_A00.tar.gz](https://dl.dell.com/FOLDER13988164M/1/Dell-iDRACTools-Web-LX-11.4.0.0-1435_A00.tar.gz) (direct link)

## Setup

Copy the example environment file and fill in your iDRAC credentials:

```bash
cp .env.example .env
```

| Variable | Description |
|---|---|
| `IDRAC_IP` | iDRAC management IP address |
| `IDRAC_USER` | iDRAC username |
| `IDRAC_PASS` | iDRAC password |
| `IDRAC_TARBALL` | Filename of the Dell iDRAC Tools tarball |

## Build

The Dockerfile uses a multi-stage build. The first stage installs `alien` (which pulls in Perl, RPM tools, etc.) to convert Dell's RHEL RPMs into Debian packages. The second stage copies only `/opt/dell` into a clean `debian:bookworm-slim` image with `libssl`. This keeps the final image at ~80-100 MB instead of ~400-500 MB if build dependencies were left in.

```bash
make build
```

## Usage

```bash
make help
```

```
  build            Build racadm:latest image
  status           Server power status
  power-on         Power on the server
  power-off        Graceful shutdown
  restart          Graceful restart (shutdown + power on)
  power-cycle      Power cycle (hard cut + power on)
  hard-reset       Hard reset (forced reboot)
  cmd              Run any RACADM command (make cmd CMD="...")
```

### Power management

```bash
make status       # check current power state
make power-on     # start the server
make power-off    # graceful OS shutdown
make restart      # graceful shutdown, wait 30s, power on
make power-cycle  # hard power cut + immediate power on
make hard-reset   # forced reboot
```

### Multiple servers

To manage several iDRAC hosts, create separate env files (e.g. `.env.node01`, `.env.node02`) and pass `ENV_FILE`:

```bash
make status ENV_FILE=.env.node02
make power-off ENV_FILE=.env.node03
```

### SSL certificate warning

The `--nocertwarn` flag is included in the entrypoint by default, so self-signed iDRAC certificates won't produce security alerts. To re-enable certificate validation, remove `--nocertwarn` from the `entrypoint` in `docker-compose.yml`.

### Custom commands

Any RACADM command can be passed through `make cmd`:

```bash
make cmd CMD="getsysinfo"
make cmd CMD="hwinventory"
make cmd CMD="getversion"
make cmd CMD="getsel"
make cmd CMD="getniccfg"
make cmd CMD="storage get pdisks"
make cmd CMD="storage get vdisks"
```

### Direct docker compose

```bash
docker compose run --rm racadm getsysinfo
docker compose run --rm racadm serveraction powerstatus
```
