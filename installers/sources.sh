#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2034
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bootstrap_sources.sh"

declare -gA GET_BASHED_GIT_SOURCES=()
GET_BASHED_GIT_SOURCES["asdf"]="https://github.com/asdf-vm/asdf.git"
GET_BASHED_GIT_SOURCES["asdf_java_plugin"]="https://github.com/halcyon/asdf-java.git"
GET_BASHED_GIT_SOURCES["asdf_nodejs_plugin"]="https://github.com/asdf-vm/asdf-nodejs.git"
GET_BASHED_GIT_SOURCES["asdf_python_plugin"]="https://github.com/danhper/asdf-python.git"
GET_BASHED_GIT_SOURCES["bash_it"]="https://github.com/Bash-it/bash-it.git"
GET_BASHED_GIT_SOURCES["vimrc"]="https://github.com/amix/vimrc.git"
GET_BASHED_GIT_SOURCES["shdoc"]="https://github.com/reconquest/shdoc.git"
GET_BASHED_GIT_SOURCES["bats_assert"]="https://github.com/bats-core/bats-assert.git"
GET_BASHED_GIT_SOURCES["bats_file"]="https://github.com/bats-core/bats-file.git"
GET_BASHED_GIT_SOURCES["bats_support"]="https://github.com/bats-core/bats-support.git"
readonly GET_BASHED_GIT_SOURCES

declare -gA GET_BASHED_GIT_REFS=()
GET_BASHED_GIT_REFS["asdf"]="v0.18.1"
GET_BASHED_GIT_REFS["asdf_java_plugin"]="7ade6a410c178cb1655b68fe00bcfd3cdc819fd2"
GET_BASHED_GIT_REFS["asdf_nodejs_plugin"]="779c8dc84b3bdab38c2c80622d315c2c3267f74b"
GET_BASHED_GIT_REFS["asdf_python_plugin"]="abc2a03863e4d569b4f9de0d0efc1a88d96c2c12"
GET_BASHED_GIT_REFS["bash_it"]="v3.2.0"
GET_BASHED_GIT_REFS["bats_assert"]="123860c029685bc0a4150ed57ee97fc7f7cc9d31"
GET_BASHED_GIT_REFS["bats_file"]="13ad5e2ffcc360281432db3d43a306f7b3667d60"
GET_BASHED_GIT_REFS["bats_support"]="64e7436962affbe15974d181173c37e1fac70073"
GET_BASHED_GIT_REFS["vimrc"]="46294d589d15d2e7308cf76c58f2df49bbec31e8"
GET_BASHED_GIT_REFS["shdoc"]="504cac5d8001eeb0cabdb83ddb2f813b9a1fc963"
readonly GET_BASHED_GIT_REFS

declare -gA GET_BASHED_GIT_POST=()
GET_BASHED_GIT_POST["vimrc"]="install_awesome_vimrc.sh"
readonly GET_BASHED_GIT_POST

declare -gA GET_BASHED_CURL_SOURCES=()
GET_BASHED_CURL_SOURCES["brew"]="${GET_BASHED_BOOTSTRAP_BREW_URL}"
readonly GET_BASHED_CURL_SOURCES

declare -gA GET_BASHED_CURL_CMD=()
GET_BASHED_CURL_CMD["brew"]="${GET_BASHED_BOOTSTRAP_BREW_CMD}"
readonly GET_BASHED_CURL_CMD

declare -gA GET_BASHED_ASDF_PLUGIN_IDS=()
GET_BASHED_ASDF_PLUGIN_IDS["java"]="asdf_java_plugin"
GET_BASHED_ASDF_PLUGIN_IDS["nodejs"]="asdf_nodejs_plugin"
GET_BASHED_ASDF_PLUGIN_IDS["python"]="asdf_python_plugin"
readonly GET_BASHED_ASDF_PLUGIN_IDS

declare -gA GET_BASHED_ASDF_PLUGIN_SOURCES=()
GET_BASHED_ASDF_PLUGIN_SOURCES["java"]="${GET_BASHED_GIT_SOURCES["asdf_java_plugin"]}"
GET_BASHED_ASDF_PLUGIN_SOURCES["nodejs"]="${GET_BASHED_GIT_SOURCES["asdf_nodejs_plugin"]}"
GET_BASHED_ASDF_PLUGIN_SOURCES["python"]="${GET_BASHED_GIT_SOURCES["asdf_python_plugin"]}"
readonly GET_BASHED_ASDF_PLUGIN_SOURCES

declare -gA GET_BASHED_ASDF_DEFAULT_VERSIONS=()
GET_BASHED_ASDF_DEFAULT_VERSIONS["java"]="temurin-21.0.10+7.0.LTS"
GET_BASHED_ASDF_DEFAULT_VERSIONS["nodejs"]="24.14.1"
GET_BASHED_ASDF_DEFAULT_VERSIONS["python"]="3.14.4"
readonly GET_BASHED_ASDF_DEFAULT_VERSIONS

declare -gA GET_BASHED_PIPX_PACKAGES=()
GET_BASHED_PIPX_PACKAGES["bashate"]="bashate==2.1.1"
GET_BASHED_PIPX_PACKAGES["pre_commit"]="pre-commit==4.5.1"
readonly GET_BASHED_PIPX_PACKAGES

declare -gA GET_BASHED_PIP_PACKAGES=()
GET_BASHED_PIP_PACKAGES["pipx"]="pipx==1.11.1"
GET_BASHED_PIP_PACKAGES["uv"]="uv==0.9.9"
readonly GET_BASHED_PIP_PACKAGES

declare -gA GET_BASHED_NODE_GLOBAL_PACKAGES=()
GET_BASHED_NODE_GLOBAL_PACKAGES["gemini"]="@google/gemini-cli@0.38.1"
GET_BASHED_NODE_GLOBAL_PACKAGES["sonar"]="@sonar/scan@4.3.6"
readonly GET_BASHED_NODE_GLOBAL_PACKAGES

declare -gr GET_BASHED_ACTIONLINT_VERSION="1.7.12"
declare -gr GET_BASHED_ACTIONLINT_TAG="v${GET_BASHED_ACTIONLINT_VERSION}"

declare -gA GET_BASHED_ACTIONLINT_SHA256=()
GET_BASHED_ACTIONLINT_SHA256["darwin_amd64"]="5b44c3bc2255115c9b69e30efc0fecdf498fdb63c5d58e17084fd5f16324c644"
GET_BASHED_ACTIONLINT_SHA256["darwin_arm64"]="aba9ced2dee8d27fecca3dc7feb1a7f9a52caefa1eb46f3271ea66b6e0e6953f"
GET_BASHED_ACTIONLINT_SHA256["linux_amd64"]="8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8"
GET_BASHED_ACTIONLINT_SHA256["linux_arm64"]="325e971b6ba9bfa504672e29be93c24981eeb1c07576d730e9f7c8805afff0c6"
readonly GET_BASHED_ACTIONLINT_SHA256
