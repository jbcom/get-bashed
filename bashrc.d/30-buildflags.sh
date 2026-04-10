#!/usr/bin/env bash
# @file 30-buildflags
# @brief get-bashed module: 30-buildflags
# @description
#     Runtime module loaded by get-bashed in lexicographic order.

# Build flags for compiling language runtimes (optional)
# Enable with GET_BASHED_BUILD_FLAGS=1
if [[ "${GET_BASHED_BUILD_FLAGS:-0}" == "1" ]] && command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(dirname "$(dirname "$(command -v brew)")")"
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

  export LDFLAGS="${_ldflags}${LDFLAGS:-}"
  export CPPFLAGS="${_cppflags}${CPPFLAGS:-}"
  export PKG_CONFIG_PATH="${_pkgconfig}${PKG_CONFIG_PATH:-}"
  export LIBRARY_PATH="${_libpath}${LIBRARY_PATH:-}"
  export CPATH="${_cpath}${CPATH:-}"
  export PYTHON_CONFIGURE_OPTS="${_pyopts}${PYTHON_CONFIGURE_OPTS:-}"
fi
