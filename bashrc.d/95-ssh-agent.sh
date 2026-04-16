#!/usr/bin/env bash
# @file 95-ssh-agent
# @brief get-bashed module: 95-ssh-agent
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Start SSH agent in interactive TTYs.
# GET_BASHED_TEST_TTY is a test-only override for non-interactive harnesses.
if [[ "${GET_BASHED_SSH_AGENT:-0}" == "1" ]] &&
  { [[ -t 1 ]] || [[ "${GET_BASHED_TEST_TTY:-0}" == "1" ]]; }; then
  _ssh_agent_usable() {
    local sock="$1" rc
    [[ -S "$sock" ]] || return 1
    SSH_AUTH_SOCK="$sock" SSH_AGENT_PID="" ssh-add -l >/dev/null 2>&1
    rc=$?
    [[ $rc -eq 0 || $rc -eq 1 ]]
  }

  if [[ -n "${SSH_AUTH_SOCK:-}" ]] && _ssh_agent_usable "$SSH_AUTH_SOCK"; then
    :
  else
    SSH_DIR="${HOME}/.ssh"
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR" 2>/dev/null || true
    SSH_AGENT_SOCK="${SSH_DIR}/agent.sock"
    if _ssh_agent_usable "$SSH_AGENT_SOCK"; then
      export SSH_AUTH_SOCK="$SSH_AGENT_SOCK"
    else
      old_umask="$(umask)"
      umask 077
      eval "$(ssh-agent -a "$SSH_AGENT_SOCK" -s)" >/dev/null
      umask "$old_umask"
    fi
  fi

  current_agent_key="${SSH_AUTH_SOCK:-}:${SSH_AGENT_PID:-}"
  if [[ "${GET_BASHED_SSH_KEYS_ADDED_FOR:-}" != "$current_agent_key" ]]; then
    if [[ -f "$HOME/.ssh/id_rsa" ]]; then
      ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true
    fi
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
      ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
    fi
    export GET_BASHED_SSH_KEYS_ADDED_FOR="$current_agent_key"
  fi
fi
