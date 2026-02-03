# @file 65-tools
# @brief get-bashed module: 65-tools
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Optional CLI tool installer (manual)
# Set GET_BASHED_AUTO_TOOLS=1 to run on shell startup.

install_cli_tools() {
  command -v asdf >/dev/null 2>&1 || return 0

  if ! command -v gemini >/dev/null 2>&1; then
    asdf exec npm install -g @google/gemini-cli
  fi

  if ! command -v sonar >/dev/null 2>&1; then
    asdf exec npm install -g @sonar/scan
  fi
}

if [[ "${GET_BASHED_AUTO_TOOLS:-0}" == "1" ]]; then
  install_cli_tools
fi
