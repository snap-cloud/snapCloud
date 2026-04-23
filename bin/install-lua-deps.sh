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
# Forcing the C++ compiler back to gnu++14 restores the permissive behavior
# and lets the rock build. This is a compile-time setting only; the resulting
# module is unchanged at runtime.
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

# Force g++ to accept xml's pre-C++17 source. We point CXX at g++ with the
# older standard; builds that respect CXX (most luarocks builtin/make builds
# do) pick this up automatically. `sudo -E` is required so the env var
# survives the privilege transition.
export CXX="${CXX:-g++} -std=gnu++14"
export CXXFLAGS="${CXXFLAGS:-} -std=gnu++14"

run_luarocks() {
    if [ -n "$SUDO" ]; then
        $SUDO -E "$LUAROCKS" "$@"
    else
        "$LUAROCKS" "$@"
    fi
}

echo ">>> Installing Lua dependencies (lua $LUA_VERSION, CXX=$CXX)"
run_luarocks install --lua-version="$LUA_VERSION" \
    --only-deps snapcloud-dev-0.rockspec
echo ">>> Lua dependencies installed."
