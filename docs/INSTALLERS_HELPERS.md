# installers-helpers

Shared helpers for installers.

## Overview

Provides platform detection and package manager helpers used by
installer scripts.

## Index

* [asdf_has_plugin](#asdfhasplugin)
* [asdf_install_plugin](#asdfinstallplugin)
* [pipx_install](#pipxinstall)

### asdf_has_plugin

Check if an asdf plugin is installed.

#### Arguments

* **$1** (string): Plugin name.

#### Exit codes

* **0**: If installed.
* **1**: If missing.

### asdf_install_plugin

Install an asdf plugin if missing.

#### Arguments

* **$1** (string): Plugin name.
* **$2** (string): Plugin repo (optional).

#### Exit codes

* **0**: If installed or already present.
* **1**: If asdf not available.

### pipx_install

Install a Python tool via pipx (fallback to pip).

#### Arguments

* **$1** (string): Package name.

#### Exit codes

* **0**: If installed.
* **1**: If pipx/pip missing.

