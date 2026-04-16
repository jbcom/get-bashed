#!/usr/bin/env bash
# @file 30-buildflags
# @brief get-bashed module: 30-buildflags
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Build flags for compiling language runtimes (optional)
# Enable with GET_BASHED_BUILD_FLAGS=1
if [[ "${GET_BASHED_BUILD_FLAGS:-0}" == "1" ]] && BREW_PREFIX="$(get_brew_prefix)"; then
  _join_space_prefix() {
    local prefix="$1"
    local current="${2:-}"

    if [[ -n "$prefix" && -n "$current" ]]; then
      printf '%s %s\n' "$prefix" "$current"
    elif [[ -n "$prefix" ]]; then
      printf '%s\n' "$prefix"
    else
      printf '%s\n' "$current"
    fi
  }

  _join_path_prefix() {
    local prefix="$1"
    local current="${2:-}"

    if [[ -n "$prefix" && -n "$current" ]]; then
      printf '%s:%s\n' "$prefix" "$current"
    elif [[ -n "$prefix" ]]; then
      printf '%s\n' "$prefix"
    else
      printf '%s\n' "$current"
    fi
  }

  OPENSSL_PREFIX="$BREW_PREFIX/opt/openssl@3"
  [[ -d "$OPENSSL_PREFIX" ]] || OPENSSL_PREFIX="$BREW_PREFIX/opt/openssl"
  READLINE_PREFIX="$BREW_PREFIX/opt/readline"
  GETTEXT_PREFIX="$BREW_PREFIX/opt/gettext"
  ZSTD_PREFIX="$BREW_PREFIX/opt/zstd"

  _ldflags=""
  _cppflags=""
  _pkgconfig=""
  _libpath=""
  _cpath=""
  _pyopts=""

  [[ -d "$OPENSSL_PREFIX/lib" ]] && {
    _ldflags+="-L${OPENSSL_PREFIX}/lib "
    _cppflags+="-I${OPENSSL_PREFIX}/include "
    _pkgconfig+="${OPENSSL_PREFIX}/lib/pkgconfig:"
    _libpath+="${OPENSSL_PREFIX}/lib:"
    _cpath+="${OPENSSL_PREFIX}/include:"
    _pyopts+="--with-openssl=${OPENSSL_PREFIX} "
  }
  [[ -d "$READLINE_PREFIX/lib" ]] && {
    _ldflags+="-L${READLINE_PREFIX}/lib "
    _cppflags+="-I${READLINE_PREFIX}/include "
    _pkgconfig+="${READLINE_PREFIX}/lib/pkgconfig:"
    _libpath+="${READLINE_PREFIX}/lib:"
    _cpath+="${READLINE_PREFIX}/include:"
    _pyopts+="--with-readline=editline "
  }
  [[ -d "$GETTEXT_PREFIX/lib" ]] && {
    _ldflags+="-L${GETTEXT_PREFIX}/lib "
    _cppflags+="-I${GETTEXT_PREFIX}/include "
    _pkgconfig+="${GETTEXT_PREFIX}/lib/pkgconfig:"
    _libpath+="${GETTEXT_PREFIX}/lib:"
    _cpath+="${GETTEXT_PREFIX}/include:"
  }
  [[ -d "$ZSTD_PREFIX/lib" ]] && {
    _ldflags+="-L${ZSTD_PREFIX}/lib "
    _cppflags+="-I${ZSTD_PREFIX}/include "
    _pkgconfig+="${ZSTD_PREFIX}/lib/pkgconfig:"
    _libpath+="${ZSTD_PREFIX}/lib:"
    _cpath+="${ZSTD_PREFIX}/include:"
  }

  _ldflags="${_ldflags% }"
  _cppflags="${_cppflags% }"
  _pkgconfig="${_pkgconfig%:}"
  _libpath="${_libpath%:}"
  _cpath="${_cpath%:}"
  _pyopts="${_pyopts% }"

  LDFLAGS="$(_join_space_prefix "$_ldflags" "${LDFLAGS:-}")"
  CPPFLAGS="$(_join_space_prefix "$_cppflags" "${CPPFLAGS:-}")"
  PKG_CONFIG_PATH="$(_join_path_prefix "$_pkgconfig" "${PKG_CONFIG_PATH:-}")"
  LIBRARY_PATH="$(_join_path_prefix "$_libpath" "${LIBRARY_PATH:-}")"
  CPATH="$(_join_path_prefix "$_cpath" "${CPATH:-}")"
  PYTHON_CONFIGURE_OPTS="$(_join_space_prefix "$_pyopts" "${PYTHON_CONFIGURE_OPTS:-}")"

  export LDFLAGS CPPFLAGS PKG_CONFIG_PATH LIBRARY_PATH CPATH PYTHON_CONFIGURE_OPTS
fi
