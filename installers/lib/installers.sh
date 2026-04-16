# @description Install GNU tools (handler).
install_gnu_tools() {
  if _using_brew; then
    brew_exec install coreutils findutils gnu-sed gnu-tar
    return $?
  fi

  echo "GNU tools install requires Homebrew." >&2
  return 1
}

# @description Install shdoc (handler).
install_shdoc() {
  local prefix bindir tmp_dir target

  if command -v shdoc >/dev/null 2>&1; then
    return 0
  fi
  if pkg_install shdoc; then
    return 0
  fi

  if command -v yay >/dev/null 2>&1; then
    if _auto_approved; then
      yay -S --noconfirm shdoc-git && return 0
    else
      yay -S shdoc-git && return 0
    fi
  elif command -v paru >/dev/null 2>&1; then
    if _auto_approved; then
      paru -S --noconfirm shdoc-git && return 0
    else
      paru -S shdoc-git && return 0
    fi
  fi

  echo "shdoc is not available via the detected package manager." >&2
  echo "Attempting local install to GET_BASHED_HOME/bin without sudo." >&2

  _using_git || {
    echo "git is required to install shdoc." >&2
    return 1
  }
  pkg_install gawk gawk gawk gawk || true

  prefix="$(_tool_prefix)"
  bindir="$prefix/bin"
  mkdir -p "$bindir"

  tmp_dir="$(mktemp -d)"
  _clone_at_ref "shdoc" "${GET_BASHED_GIT_SOURCES["shdoc"]}" "$tmp_dir/shdoc" || {
    rm -rf "$tmp_dir"
    return 1
  }

  target="$bindir/shdoc"
  {
    echo '#!/usr/bin/env -S gawk -f'
    tail -n +2 "$tmp_dir/shdoc/shdoc"
  } > "$target"
  chmod +x "$target"
  rm -rf "$tmp_dir"
}

# @description Install vimrc (handler).
install_vimrc() {
  local prefix target

  prefix="$(_tool_prefix)"
  target="$prefix/vendor/vimrc"
  mkdir -p "$prefix/vendor"
  _ensure_git_checkout_at_ref "vimrc" "${GET_BASHED_GIT_SOURCES["vimrc"]}" "$target" || return 1

  case "${GET_BASHED_VIMRC_MODE:-awesome}" in
    basic)
      sh "$target/install_basic_vimrc.sh"
      ;;
    *)
      sh "$target/install_awesome_vimrc.sh"
      ;;
  esac
}

# @description Install actionlint (handler).
install_actionlint() {
  local os arch prefix url tmp_dir asset_name checksum_key expected_checksum actual_checksum

  if command -v actionlint >/dev/null 2>&1; then
    return 0
  fi

  if _using_brew; then
    brew_exec install actionlint && return 0
  fi
  if command -v apt-get >/dev/null 2>&1 && apt_install actionlint; then
    return 0
  fi

  _using_curl || {
    echo "curl is required to install actionlint" >&2
    return 1
  }

  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "$arch" in
    x86_64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
  esac

  case "$os" in
    darwin|linux) ;;
    *)
      echo "Unsupported OS for actionlint: $os" >&2
      return 1
      ;;
  esac

  asset_name="actionlint_${GET_BASHED_ACTIONLINT_VERSION}_${os}_${arch}.tar.gz"
  checksum_key="${os}_${arch}"
  expected_checksum="${GET_BASHED_ACTIONLINT_SHA256[$checksum_key]:-}"
  if [[ -z "$expected_checksum" ]]; then
    echo "No pinned checksum configured for actionlint asset ${checksum_key}." >&2
    return 1
  fi

  url="https://github.com/rhysd/actionlint/releases/download/${GET_BASHED_ACTIONLINT_TAG}/${asset_name}"
  tmp_dir="$(mktemp -d)"
  if ! curl -fsSL "$url" -o "$tmp_dir/actionlint.tgz"; then
    rm -rf "$tmp_dir"
    echo "Failed to download actionlint from $url" >&2
    return 1
  fi
  if ! actual_checksum="$(sha256_file "$tmp_dir/actionlint.tgz")"; then
    rm -rf "$tmp_dir"
    return 1
  fi
  if [[ "$actual_checksum" != "$expected_checksum" ]]; then
    rm -rf "$tmp_dir"
    echo "Actionlint checksum mismatch for ${asset_name}." >&2
    return 1
  fi
  if ! tar -xzf "$tmp_dir/actionlint.tgz" -C "$tmp_dir"; then
    rm -rf "$tmp_dir"
    echo "Failed to extract actionlint archive." >&2
    return 1
  fi

  prefix="$(_tool_prefix)"
  mkdir -p "$prefix/bin"
  mv "$tmp_dir/actionlint" "$prefix/bin/actionlint"
  chmod +x "$prefix/bin/actionlint"
  rm -rf "$tmp_dir"
}
