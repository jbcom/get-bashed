# @file 66-doppler
# @brief get-bashed module: 66-doppler
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Optional Doppler integration (requires doppler CLI)
# Enable with GET_BASHED_USE_DOPPLER=1
#
# NOTE: We intentionally do not auto-source doppler in shell init.
# Some integrated terminals can break if doppler is invoked during startup.

if [[ "${GET_BASHED_USE_DOPPLER:-0}" == "1" ]] && command -v doppler >/dev/null 2>&1; then
  export DOPPLER_PROJECT="${DOPPLER_PROJECT:-}"
  export DOPPLER_CONFIG="${DOPPLER_CONFIG:-}"

  # @description Start a subshell with doppler-injected env.
  # @example
  #   doppler_shell
  doppler_shell() {
    doppler run -- bash
  }
fi
