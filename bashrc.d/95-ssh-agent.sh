#!/usr/bin/env bash
# @file 95-ssh-agent
# @brief get-bashed module: 95-ssh-agent
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Start SSH agent in interactive TTYs
if [[ "${GET_BASHED_SSH_AGENT:-0}" == "1" ]] && [[ -t 1 ]]; then
  eval "$(ssh-agent -s)" >/dev/null
  [[ -f "$HOME/.ssh/id_rsa" ]] && ssh-add "$HOME/.ssh/id_rsa" 2>/dev/null || true
  [[ -f "$HOME/.ssh/id_ed25519" ]] && ssh-add "$HOME/.ssh/id_ed25519" 2>/dev/null || true
fi
