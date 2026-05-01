#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Install Snap!Cloud's pinned Lua dependencies.
#
# The repo's luarocks.lock pins `xml-1.1.3-1`, which is an old C++ rock whose
# bundled header `src/bind/dub/dub.h` uses pre-C++17 dynamic exception
# specifications. On Ubuntu 22.04+ (gcc 11) and recent macOS/clang, the
# default C++ dialect is C++17, so the compile fails with:
#
#   error: ISO C++17 does not allow dynamic exception specifications
#
# Forcing g++ back to gnu++14 restores the permissive behavior. Setting
# CXX/CXXFLAGS env vars isn't reliable here:
#   - luarocks's builtin build doesn't always honor CXX from the env
#     (it reads cfg.variables, which env vars can't override mid-call)
#   - sudo strips env vars by default, even with -E in some configs
#   - the rock's own Makefile may or may not respect CXXFLAGS
#
# Instead, we put a tiny `g++` wrapper at the front of PATH that always
# appends `-std=gnu++14`. This works regardless of build type (builtin /
# make / cmake) because every C++ compile resolves `g++` via PATH. Pure C
# compiles still use `gcc`, which we leave alone.
#
# Usage:
#   bin/install-lua-deps.sh               # dev/CI default
#   LUA_VERSION=5.1 bin/install-lua-deps.sh
#   SUDO=sudo bin/install-lua-deps.sh     # when installing to a system tree
# -----------------------------------------------------------------------------
set -euo pipefail

LUA_VERSION="${LUA_VERSION:-5.1}"

# Use sudo for system-wide installs (CI, fresh Linux dev boxes). Default to
# empty so developers with a user-local luarocks tree (e.g. via luaver /
# hererocks) aren't prompted for a password they don't need.
SUDO="${SUDO:-}"

# Pick a luarocks binary. macOS developers tend to use the bundled
# `bin/luarocks-macos` wrapper; Linux uses the system luarocks.
if [ -z "${LUAROCKS:-}" ]; then
    case "$(uname -s)" in
        Darwin) LUAROCKS="$(dirname "$0")/luarocks-macos" ;;
        *)      LUAROCKS="luarocks" ;;
    esac
fi

# -----------------------------------------------------------------------------
# Build a g++ shim that injects -std=gnu++14, then put it first on PATH.
# -----------------------------------------------------------------------------
SHIM_DIR="$(mktemp -d -t snapcloud-cxx-shim.XXXXXX)"
trap 'rm -rf "$SHIM_DIR"' EXIT

REAL_GXX="$(command -v g++ || true)"
if [ -z "$REAL_GXX" ]; then
    echo "install-lua-deps.sh: g++ not found on PATH; install build-essential first" >&2
    exit 1
fi

cat > "$SHIM_DIR/g++" <<EOF
#!/bin/sh
# Snap!Cloud install-time shim: forces gnu++14 so the pinned xml-1.1.3
# rock compiles on modern toolchains. Real compiler: $REAL_GXX
exec "$REAL_GXX" -std=gnu++14 "\$@"
EOF
chmod +x "$SHIM_DIR/g++"

# Also expose the shim as `c++` (some Makefiles invoke that name).
ln -sf "$SHIM_DIR/g++" "$SHIM_DIR/c++"

SHIMMED_PATH="$SHIM_DIR:$PATH"

run_luarocks() {
    if [ -n "$SUDO" ]; then
        # `sudo env PATH=...` survives sudo's default env scrubbing without
        # depending on `Defaults env_keep` being configured for PATH.
        $SUDO env "PATH=$SHIMMED_PATH" "$LUAROCKS" "$@"
    else
        PATH="$SHIMMED_PATH" "$LUAROCKS" "$@"
    fi
}

echo ">>> Installing Lua dependencies (lua $LUA_VERSION)"
echo ">>> Using g++ shim at $SHIM_DIR/g++ -> $REAL_GXX -std=gnu++14"

# Install xml first, in isolation, so any failure is unambiguous and so the
# subsequent --only-deps run finds it already present and skips rebuild.
run_luarocks install --lua-version="$LUA_VERSION" xml

# Install the remaining project deps from the rockspec (uses luarocks.lock).
run_luarocks install --lua-version="$LUA_VERSION" \
    --only-deps snapcloud-dev-0.rockspec

echo ">>> Lua dependencies installed."
