# Moodle Docker Deployment

This folder contains a Docker Compose setup for running Moodle with:

- `moodle` (PHP-FPM + Moodle code baked into the image)
- `nginx` (serves static files + forwards PHP requests to PHP-FPM)
- `db` (MySQL)
- `redis` (optional session backend)
- `cron` (runs Moodle scheduled tasks)

Moodle code is **baked into the images** (immutable image approach). Persistent state is kept in the database and in `moodledata`.

Default versions:

- Moodle: `stable401` / `4.1.22`
- PHP (moodle image): `8.0-fpm`
- MySQL (db image): `8.0.42`

## Baked plugins / theme (defaults)

The following theme/plugins are baked into the Docker images by default (see `docker-compose.yml` build args and `.env.example` overrides).

| Type | Component | Version / build | Default source URL |
| --- | --- | --- | --- |
| Theme | `theme_adaptable` | `moodle41_2022112316` | `https://moodle.org/plugins/download.php/35469/theme_adaptable_moodle41_2022112316.zip` |
| Local plugin | `local_profilecohort` | `moodle41_2023010506` | `https://moodle.org/plugins/download.php/33641/local_profilecohort_moodle41_2023010506.zip` |
| Local plugin | `local_cnw_smartcohort` | `moodle42_2023081800` | `https://moodle.org/plugins/download.php/29804/local_cnw_smartcohort_moodle42_2023081800.zip` |
| Block | `block_coursefeedback` | `moodle44_2025022700` | `https://moodle.org/plugins/download.php/35159/block_coursefeedback_moodle44_2025022700.zip` |

## Prerequisites

- Docker Desktop (or Docker Engine)
- Docker Compose v2 (`docker compose`)

## Quickstart

### Build images

```sh
make build
```

### Start the stack

```sh
make up
```

Open Moodle:

```text
http://localhost:8080
```

### Stop the stack (keep data)

```sh
make down
```

### Stop the stack and delete volumes (wipe data)

```sh
make kill
```

## Persistence (data storage)

There are two supported persistence modes:

- **Named volumes (default)**
  - Data is managed by Docker.
  - Persists across `make down`.
  - Removed by `make kill` (because it runs `docker compose down -v`).

- **Bind mounts (host folders)**
  - Data is stored in specific folders on your machine.
  - Useful for backups / inspection / explicit control.

### Use bind mounts (host folders)

This will store data in `./data/dbdata` and `./data/moodledata`.

```sh
make up DATA_MODE=bind
```

### Use bind mounts with a custom base directory

```sh
make up DATA_MODE=bind DATA_DIR=../persistent
```

### Override each data location explicitly

```sh
make up \
  DBDATA_SOURCE=/srv/moodle/dbdata \
  MOODLEDATA_SOURCE=/srv/moodle/moodledata
```

## Common commands

### Follow logs

```sh
make logs
```

### Show container status

```sh
make ps
```

### Render the final Compose config (after env var substitution)

```sh
make config
```

### Get a shell in the Moodle container

```sh
make exec-shell
```

### Run a command in the Moodle container

Example: run cron once manually.

```sh
make exec-moodle CMD='php /var/www/html/admin/cli/cron.php'
```

### Connect to MySQL

```sh
make exec-db
```

## Moodle configuration via environment variables

The container entrypoint generates `config.php` if it does not exist yet, using environment variables.

Common variables (see `php/Dockerfile` for defaults):

- `MOODLE_WWWROOT`
- `MOODLE_DBTYPE` (default: `mysqli`)
- `MOODLE_DBHOST` (default: `db`)
- `MOODLE_DBNAME`
- `MOODLE_DBUSER`
- `MOODLE_DBPASSWORD`
- `MOODLE_DBPREFIX`
- `MOODLE_DATAROOT` (default: `/var/www/moodledata`)
- `MOODLE_REDIS_HOST` (optional)
- `MOODLE_REVERSEPROXY`, `MOODLE_SSLPROXY`, `MOODLE_ROUTERCONFIGURED`

PHP runtime tuning variables (evaluated at container startup):

- `PHP_DISPLAY_ERRORS` (default: `0`)
- `PHP_LOG_ERRORS` (default: `1`)
- `PHP_EXPOSE_PHP` (default: `0`)
- `PHP_ERROR_REPORTING` (default: `E_ALL&~E_DEPRECATED&~E_STRICT`)

Note: `config.php` is only generated when missing. If you change env vars after the first run, you must update `config.php` yourself or delete it and let it be regenerated.

## Automated installation (optional)

If you want the container to run the Moodle CLI installer automatically, set:

- `MOODLE_RUN_INSTALL=1`

and provide the required site/admin variables (defaults exist in the image, but you should override them for real deployments):

- `MOODLE_SITE_FULLNAME`
- `MOODLE_SITE_SHORTNAME`
- `MOODLE_ADMIN_USER`
- `MOODLE_ADMIN_PASSWORD`
- `MOODLE_ADMIN_EMAIL`

## Upgrading Moodle (code + database)

When you rebuild the images with a newer Moodle version, `config.php` is **not** regenerated and the installer is **not** re-run.
To upgrade the database schema you must run the Moodle upgrade step.

This setup supports an env-controlled upgrade on container startup:

- `MOODLE_RUN_UPGRADE=1` will run `php /var/www/html/admin/cli/upgrade.php --non-interactive` (as `www-data`).

Example upgrade workflow:

```sh
make down
docker compose build --build-arg MOODLE_SERIES=stable401 --build-arg MOODLE_VERSION=4.1.22 moodle nginx
MOODLE_RUN_UPGRADE=1 docker compose up -d
docker compose logs -f --tail=200
```

After the upgrade completed successfully you can remove the flag again (recommended):

```sh
make down
make up
```

### Example: upgrade between Moodle series (e.g. stable401 -> stable405)

1) Update the build args in `docker-compose.yml` for both `moodle` and `nginx`:

```yaml
args:
  MOODLE_SERIES: stable405
  MOODLE_VERSION: latest-405
```

2) Rebuild images:

```sh
make down
make build
```

3) Start the stack once with the upgrade enabled:

```sh
MOODLE_RUN_UPGRADE=1 docker compose up -d
docker compose logs -f --tail=200 moodle
```

4) Verify the upgrade is no longer pending:

```sh
docker compose exec moodle php /var/www/html/admin/cli/upgrade.php --is-pending; echo $?
```

Exit code meanings:

- `0`: no upgrade pending
- `2`: upgrade pending

5) Restart without the upgrade flag:

```sh
make down
make up
```

Notes:

- Some Moodle versions may require serving the webroot from a `/public` directory. If you see the `error/rootdirpublic` message, ensure nginx uses the correct `root` directory.
- During upgrades cron may print `Moodle upgrade pending, cron execution suspended.`. This setup waits for the upgrade to complete before starting the cron loop.

## Notes for deployments

- Two images are built:
  - `moodle-docker-moodle` (PHP-FPM + Moodle)
  - `moodle-docker-nginx` (nginx + Moodle static files)
- Only `moodledata` and the database are intended to be persisted.

## Troubleshooting

### "Composer vendor directory not found"

The PHP image runs `composer install --no-dev --classmap-authoritative` at build time, so `/var/www/html/vendor` should exist.
If you changed the Dockerfile or the Moodle version, rebuild the image:

```sh
make build
```

### Security warning: `zend.exception_ignore_args`

This is enabled in `php/php.ini`.
Rebuild if you changed PHP config:

```sh
make build
```
