#!/bin/sh

# shellcheck disable=SC2034

: "${GET_BASHED_BOOTSTRAP_BREW_URL:=https://raw.githubusercontent.com/Homebrew/install/de0b0bddf1c78731dcd16d953b2f5d29d070e229/install.sh}"
: "${GET_BASHED_BOOTSTRAP_BREW_SHA256:=dfd5145fe2aa5956a600e35848765273f5798ce6def01bd08ecec088a1268d91}"
: "${GET_BASHED_BOOTSTRAP_BREW_CMD:=/bin/bash}"
: "${GET_BASHED_BOOTSTRAP_REPO_ARCHIVE_URL:=https://github.com/jbcom/get-bashed/archive/22eff2b26037a7db4548e3996e587173cf2aa053.tar.gz}"
: "${GET_BASHED_BOOTSTRAP_REPO_ARCHIVE_SHA256:=87aeecd8e12143ccb019cec367df9923b56977c6730df578384795c0d688a630}"
