# get-bashed-installer

Installer and configurator for get-bashed.

## Overview

Supports non-interactive and interactive installation with profiles,
feature flags, and installer bundles.

## Index

* [usage](#usage)
* [apply_profile](#applyprofile)
* [apply_feature](#applyfeature)
* [split_csv](#splitcsv)

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

