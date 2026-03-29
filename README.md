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
| `RESTART_WAIT_SEC` | Seconds to wait between graceful shutdown and power on (`make restart`) |

## Build

The Dockerfile uses a multi-stage build. The first stage installs `alien` (which pulls in Perl, RPM tools, etc.) to convert Dell's RHEL RPMs into Debian packages. The second stage copies only `/opt/dell` into a clean `debian:bookworm-slim` image with `libssl`. This keeps the final image at ~80-100 MB instead of ~400-500 MB if build dependencies were left in.

```bash
make build
```

## Usage

The image does **not** set a Docker `ENTRYPOINT` or `CMD` for RACADM. Each run supplies the full command: the **Compose service name** is `racadm`, and the **program inside the container** is also `racadm`, followed by `--nocertwarn`, `-r` / `-u` / `-p`, and the RACADM subcommand.

The **Makefile** loads your `.env` (same file as `docker compose --env-file`) and expands those variables into the `docker compose run … racadm racadm …` line so you do not retype credentials.

```bash
make help
```

Typical targets include `build`, `status`, `info`, `inventory`, `version`, `sel`, power actions (`power-on`, `power-off`, `restart`, `power-cycle`, `hard-reset`), `idrac-reset`, `idrac-info`, and `cmd`. Run `make help` for the full list and descriptions.

### Power management

```bash
make status       # check current power state
make power-on     # start the server
make power-off    # graceful OS shutdown
make restart      # graceful shutdown, wait RESTART_WAIT_SEC, power on
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

`--nocertwarn` is added on every run in the Makefile (`COMPOSE` variable) so self-signed iDRAC certificates do not trigger certificate warnings. To enforce certificate validation, remove `--nocertwarn` from that line in the `Makefile` (or omit it when invoking `docker compose` manually).

### Custom commands

Any RACADM arguments after the connection flags can be passed through `make cmd`:

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

Without Make, you must pass the **binary name** `racadm` after the service name, then connection flags, then the RACADM subcommand. Use `--env-file` so Compose can substitute build-time variables (e.g. `IDRAC_TARBALL`); export or expand `IDRAC_*` in your shell for `-r` / `-u` / `-p`:

```bash
set -a && source .env && set +a
docker compose --env-file .env run --rm racadm \
  racadm --nocertwarn -r "$IDRAC_IP" -u "$IDRAC_USER" -p "$IDRAC_PASS" \
  getsysinfo

docker compose --env-file .env run --rm racadm \
  racadm --nocertwarn -r "$IDRAC_IP" -u "$IDRAC_USER" -p "$IDRAC_PASS" \
  serveraction powerstatus
```

Replace `getsysinfo` / `serveraction powerstatus` with any other RACADM subcommand you need.
