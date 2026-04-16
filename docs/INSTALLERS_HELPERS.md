# installers-helpers

Shared helpers for installers.

## Overview

Provides platform detection, pinned sources, and installation helpers
used by installer scripts.

## Index

* [auto_exec](#auto_exec)
* [pipx_package_spec](#pipx_package_spec)
* [pip_package_spec](#pip_package_spec)
* [pipx_install](#pipx_install)
* [asdf_has_plugin](#asdf_has_plugin)
* [asdf_install_plugin](#asdf_install_plugin)
* [asdf_plugin_source](#asdf_plugin_source)
* [asdf_plugin_ref](#asdf_plugin_ref)
* [asdf_pin_plugin_ref](#asdf_pin_plugin_ref)
* [asdf_default_version](#asdf_default_version)
* [component_install](#component_install)
* [install_tool](#install_tool)
* [install_gnu_tools](#install_gnu_tools)
* [install_shdoc](#install_shdoc)
* [install_vimrc](#install_vimrc)
* [install_actionlint](#install_actionlint)
* [install_asdf](#install_asdf)
* [install_asdf_runtime](#install_asdf_runtime)
* [install_java](#install_java)
* [install_nodejs](#install_nodejs)
* [install_python](#install_python)

### auto_exec

Run a command with auto-approval when configured.

#### Arguments

* **$1** (string): Command name.
* **$2** (string): Optional flag to auto-approve (e.g., -y, --noconfirm).
* **$3** (string): Optional extra flag (e.g., --assume-yes).
* **$4** (string): Optional extra flag (e.g., --yes).
* **$5** (string): Optional extra flag (e.g., --confirm).
* **$6** (string): Optional extra flag (e.g., --no-confirm).

### pipx_package_spec

Return the configured pipx package spec for a tool id.

#### Arguments

* **$1** (string): Tool id.

### pip_package_spec

Return the configured pip package spec for a tool id.

#### Arguments

* **$1** (string): Tool id.

### pipx_install

Install a Python tool via pipx (fallback to pip).

#### Arguments

* **$1** (string): Package name.

#### Exit codes

* **0**: If installed.
* **1**: If pipx/pip missing.

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

### asdf_plugin_source

Return the configured asdf plugin source URL.

#### Arguments

* **$1** (string): Plugin name.

### asdf_plugin_ref

Return the configured asdf plugin git ref.

#### Arguments

* **$1** (string): Plugin name.

### asdf_pin_plugin_ref

Pin an installed asdf plugin checkout to the configured ref.

#### Arguments

* **$1** (string): Plugin name.

### asdf_default_version

Return the configured default asdf runtime version.

#### Arguments

* **$1** (string): Plugin name.

### component_install

Install a component using available methods.

#### Arguments

* **$1** (string): Action (enable|disable|install).
* **$2** (string): Term to resolve/install.

### install_tool

Install a tool from the tools registry.

#### Arguments

* **$1** (string): Tool id.

### install_gnu_tools

Install GNU tools (handler).

### install_shdoc

Install shdoc (handler).

### install_vimrc

Install vimrc (handler).

### install_actionlint

Install actionlint (handler).

### install_asdf

Install asdf (handler).

### install_asdf_runtime

Install a pinned asdf runtime version.

#### Arguments

* **$1** (string): Plugin name.

### install_java

Install Java (handler).

### install_nodejs

Install Node.js (handler).

### install_python

Install Python (handler).

