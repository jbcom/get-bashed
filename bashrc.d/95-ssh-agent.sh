#!/usr/bin/env bash
# @file 95-ssh-agent
# @brief get-bashed module: 95-ssh-agent
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Start SSH agent in interactive TTYs
if [[ "${GET_BASHED_SSH_AGENT:-0}" == "1" ]] && [[ -t 1 ]]; then
  _ssh_agent_usable() {
    local sock="$1" rc
    [[ -S "$sock" ]] || return 1
    SSH_AUTH_SOCK="$sock" SSH_AGENT_PID= ssh-add -l >/dev/null 2>&1
    rc=$?
    [[ $rc -eq 0 || $rc -eq 1 ]]
  }

  if [[ -n "${SSH_AUTH_SOCK:-}" ]] && _ssh_agent_usable "$SSH_AUTH_SOCK"; then
    :
  else
    SSH_AGENT_SOCK="${HOME}/.ssh/agent.sock"
    if _ssh_agent_usable "$SSH_AGENT_SOCK"; then
      export SSH_AUTH_SOCK="$SSH_AGENT_SOCK"
    else
      eval "$(ssh-agent -a "$SSH_AGENT_SOCK" -s)" >/dev/null
    fi
  fi

  [[ -f "$HOME/.ssh/id_rsa" ]] && ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true
  [[ -f "$HOME/.ssh/id_ed25519" ]] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
fi
