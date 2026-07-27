# get-bashed-installer

Installer and configurator for get-bashed.

## ⚠️ Upgrading & Breaking Changes

**BREAKING CHANGE:** As of the latest release, get-bashed consolidates all runtime modules, local secrets, and dotfiles into a single managed prefix (default: `~/.get-bashed/`).

If you are upgrading from a legacy installation (where files were stored in `~/.bashrc.d` and `~/.secrets.d`), the installer will attempt to automatically migrate your custom scripts and secrets into the new managed prefix.

**Before upgrading, it is highly recommended to back up your custom modules:**
```bash
cp -r ~/.bashrc.d ~/bashrc.d.backup 2>/dev/null || true
cp -r ~/.secrets.d ~/secrets.d.backup 2>/dev/null || true
```

## Overview

Supports non-interactive and interactive installation with profiles,
feature flags, and installer bundles.

## Index

* [usage](#usage)
* [apply_profile](#apply_profile)
* [apply_feature](#apply_feature)
* [split_csv](#split_csv)

### usage

Print usage help.

_Function has no arguments._

### apply_profile

Apply a built-in profile.

#### Arguments

* **$1** (string): Profile name.

#### Exit codes

* **0**: If applied.
* **1**: If unknown.

### apply_feature

Apply a feature toggle.

#### Arguments

* **$1** (string): Feature name (supports no- prefix).

#### Exit codes

* **0**: If applied.
* **1**: If unknown.

### split_csv

Split a comma-delimited list into space-delimited output.

#### Arguments

* **$1** (string): Comma list.

#### Output on stdout

* Space-delimited items.

