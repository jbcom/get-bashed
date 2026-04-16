#!/usr/bin/env bash
# @file 65-tools
# @brief get-bashed module: 65-tools
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Optional CLI tool installer (manual)
# Set GET_BASHED_AUTO_TOOLS=1 to run on shell startup.

load_auto_tool_pins() {
  local prefix pins_file

  if [[ -n "${GET_BASHED_GEMINI_CLI_PACKAGE_SPEC:-}" && -n "${GET_BASHED_SONAR_SCAN_PACKAGE_SPEC:-}" ]]; then
    return 0
  fi

  prefix="${GET_BASHED_HOME:-$HOME/.get-bashed}"
  pins_file="$prefix/get-bashed-pins.sh"
  [[ -r "$pins_file" ]] || return 0

  # shellcheck disable=SC1090
  source "$pins_file"
}

node_package_installed() {
  local spec="$1"
  asdf exec npm list -g --depth=0 "$spec" >/dev/null 2>&1
}

ensure_node_global_package() {
  local spec="$1"

  node_package_installed "$spec" && return 0
  asdf exec npm install -g "$spec"
}

install_cli_tools() {
  local gemini_pkg sonar_pkg

  command -v asdf >/dev/null 2>&1 || return 0
  asdf exec npm --version >/dev/null 2>&1 || return 0

  load_auto_tool_pins
  gemini_pkg="${GET_BASHED_GEMINI_CLI_PACKAGE_SPEC:-@google/gemini-cli}"
  sonar_pkg="${GET_BASHED_SONAR_SCAN_PACKAGE_SPEC:-@sonar/scan}"

  ensure_node_global_package "$gemini_pkg"
  ensure_node_global_package "$sonar_pkg"
}

if [[ "${GET_BASHED_AUTO_TOOLS:-0}" == "1" ]]; then
  install_cli_tools
fi
