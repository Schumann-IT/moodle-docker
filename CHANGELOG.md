# Changelog

All notable changes to this Moodle Docker deployment are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [moodle-4.1.22]

### Changed

- Default Moodle build args updated to `stable401` / `4.1.22`.
- PHP base image updated to `php:8.0-fpm`.
- MySQL base image pinned to `mysql:8.0.42`.
- Updated baked theme/plugin defaults for Moodle 4.1:
  - `theme_adaptable`: `moodle41_2022112316`
  - `local_profilecohort`: `moodle41_2023010506`
  - `local_cnw_smartcohort`: `moodle42_2023081800`
  - `block_coursefeedback`: `moodle44_2025022700`

## [moodle-3.11.18]

### Added

- Initial documented Docker Compose based Moodle stack.
- Initial Moodle core version: `3.11.18`.
- Build-time baking of Moodle core into the `moodle` (PHP-FPM) and `nginx` images.
- Environment-variable driven `config.php` generation and optional one-shot install/upgrade hooks.
- Optional Redis service and a dedicated `cron` service which waits until upgrades are not pending.
- Makefile helpers for common actions (`build`, `up`, `down`, `kill`, `exec-*`, etc.).
- Standardized database service on MySQL and aligned docs and persistence naming (`dbdata`).
- Plugin/theme baking workflow:
  - Plugin/theme ZIP URLs can be overridden via build args and env vars.
  - Extraction logic expects plugin roots under their conventional Moodle paths (`theme/adaptable`, `local/profilecohort`, etc.).
- Upgrade guidance expanded to cover rebuilding images and running `admin/cli/upgrade.php` via `MOODLE_RUN_UPGRADE=1`.

