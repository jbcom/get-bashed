# installers-helpers

Shared helpers for installers.

## Overview

Provides platform detection and package manager helpers used by
installer scripts.

## Index

* [install_tool](#install_tool)
* [install_asdf](#install_asdf)
* [install_gnu_tools](#install_gnu_tools)
* [install_java](#install_java)
* [install_nodejs](#install_nodejs)
* [install_python](#install_python)
* [install_shdoc](#install_shdoc)
* [install_vimrc](#install_vimrc)
* [install_actionlint](#install_actionlint)
* [pkg_install](#pkg_install)
* [asdf_has_plugin](#asdf_has_plugin)
* [asdf_install_plugin](#asdf_install_plugin)
* [pipx_install](#pipx_install)

### install_tool

Install a tool from the tools registry.

#### Arguments

* **$1** (string): Tool id.

### install_asdf

Install asdf (handler).

### install_gnu_tools

Install GNU tools (handler).

### install_java

Install Java (handler).

### install_nodejs

Install Node.js (handler).

### install_python

Install Python (handler).

### install_shdoc

Install shdoc (handler).

### install_vimrc

Install vimrc (handler).

### install_actionlint

Install actionlint (handler).

### pkg_install

Install a package via available system package manager.

#### Arguments

* **$1** (string): Brew package name.
* **$2** (string): Apt package name (optional).
* **$3** (string): Dnf package name (optional).
* **$4** (string): Yum package name (optional).

#### Exit codes

* **0**: If installed.
* **1**: If no supported package manager.

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

