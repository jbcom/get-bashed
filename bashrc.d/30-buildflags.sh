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

  export LDFLAGS="-L${OPENSSL_PREFIX}/lib -L${READLINE_PREFIX}/lib -L${GETTEXT_PREFIX}/lib -L${ZSTD_PREFIX}/lib ${LDFLAGS}"
  export CPPFLAGS="-I${OPENSSL_PREFIX}/include -I${READLINE_PREFIX}/include -I${GETTEXT_PREFIX}/include -I${ZSTD_PREFIX}/include ${CPPFLAGS}"
  export PKG_CONFIG_PATH="${OPENSSL_PREFIX}/lib/pkgconfig:${READLINE_PREFIX}/lib/pkgconfig:${GETTEXT_PREFIX}/lib/pkgconfig:${ZSTD_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"
  export LIBRARY_PATH="${OPENSSL_PREFIX}/lib:${READLINE_PREFIX}/lib:${GETTEXT_PREFIX}/lib:${ZSTD_PREFIX}/lib:${LIBRARY_PATH}"
  export CPATH="${OPENSSL_PREFIX}/include:${READLINE_PREFIX}/include:${GETTEXT_PREFIX}/include:${ZSTD_PREFIX}/include:${CPATH}"
  export PYTHON_CONFIGURE_OPTS="--with-openssl=${OPENSSL_PREFIX} --with-readline=editline"
fi
