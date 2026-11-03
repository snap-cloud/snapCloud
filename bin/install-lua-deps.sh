#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Install Snap!Cloud's pinned Lua dependencies.
#
# The repo's luarocks.lock pins `xml-1.1.3-1`, whose bundled
# `src/bind/dub/dub.h` uses pre-C++17 dynamic exception specifications.
# On Ubuntu 22.04+ (gcc 11) and recent macOS/clang, the default C++
# dialect is C++17 and the build fails with:
#
#   error: ISO C++17 does not allow dynamic exception specifications
#
# Worse, luarocks's `builtin` build calls `gcc` (not g++) to compile
# C++ sources — it relies on gcc auto-detecting C++ from the .cpp
# extension and switching to the C++ frontend. So a g++-only shim
# doesn't intercept anything.
#
# This script puts a tiny `gcc`/`cc`/`g++`/`c++` wrapper at the front
# of PATH that injects `-std=gnu++14` *only when the args mention a
# C++ source file or -x c++*. C compiles are passed through unchanged
# so we don't add noise to every dep in the graph.
#
# Setting CXX/CXXFLAGS env vars looks simpler but isn't reliable here:
# `sudo` strips them, and luarocks's builtin build reads cfg.variables
# rather than the live environment.
#
# Usage:
#   bin/install-lua-deps.sh               # dev/CI default
#   LUA_VERSION=5.1 bin/install-lua-deps.sh
#   SUDO=sudo bin/install-lua-deps.sh     # when installing to a system tree
# -----------------------------------------------------------------------------
set -euo pipefail

LUA_VERSION="${LUA_VERSION:-5.1}"
SUDO="${SUDO:-}"

if [ -z "${LUAROCKS:-}" ]; then
    case "$(uname -s)" in
        Darwin) LUAROCKS="$(dirname "$0")/luarocks-macos" ;;
        *)      LUAROCKS="luarocks" ;;
    esac
fi

# -----------------------------------------------------------------------------
# Build a compiler shim that injects -std=gnu++14 when (and only when) it
# detects a C++ compile, then put it first on PATH.
# -----------------------------------------------------------------------------
SHIM_DIR="$(mktemp -d -t snapcloud-cc-shim.XXXXXX)"
trap 'rm -rf "$SHIM_DIR"' EXIT

REAL_GCC="$(command -v gcc || true)"
REAL_GXX="$(command -v g++ || true)"
if [ -z "$REAL_GCC" ] || [ -z "$REAL_GXX" ]; then
    echo "install-lua-deps.sh: gcc/g++ not found on PATH; install build-essential first" >&2
    exit 1
fi

cat > "$SHIM_DIR/gcc" <<EOF
#!/bin/sh
# Snap!Cloud install-time shim. Forwards to: $REAL_GCC
# Injects -std=gnu++14 when compiling C++ sources so xml-1.1.3 builds
# under the C++17-default toolchain. C compiles are unaffected.
needs_cxx=0
prev=""
for arg in "\$@"; do
    case "\$arg" in
        *.cpp|*.cxx|*.cc|*.CPP|*.CXX|*.CC|*.C++|*.c++) needs_cxx=1 ;;
    esac
    if [ "\$prev" = "-x" ] && [ "\$arg" = "c++" ]; then
        needs_cxx=1
    fi
    prev="\$arg"
done
if [ "\$needs_cxx" = "1" ]; then
    exec "$REAL_GCC" -std=gnu++14 "\$@"
else
    exec "$REAL_GCC" "\$@"
fi
EOF
chmod +x "$SHIM_DIR/gcc"

# Same logic for g++/c++/cc — link to a single implementation. The shim
# decides what to do based on its argv, not its name.
ln -sf "$SHIM_DIR/gcc" "$SHIM_DIR/cc"
ln -sf "$SHIM_DIR/gcc" "$SHIM_DIR/g++"
ln -sf "$SHIM_DIR/gcc" "$SHIM_DIR/c++"

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
echo ">>> Compiler shim: $SHIM_DIR (C++ sources -> $REAL_GCC -std=gnu++14)"

# Quick self-test so a broken shim fails loudly instead of silently letting
# the original error reproduce.
echo "int main(){return 0;}" > "$SHIM_DIR/test.cpp"
if ! "$SHIM_DIR/gcc" -c "$SHIM_DIR/test.cpp" -o "$SHIM_DIR/test.o" 2>"$SHIM_DIR/test.err"; then
    echo "install-lua-deps.sh: shim self-test failed:" >&2
    cat "$SHIM_DIR/test.err" >&2
    exit 1
fi

# Install xml first, in isolation, so any failure is unambiguous and so the
# subsequent --only-deps run finds it already present and skips rebuild.
run_luarocks install --lua-version="$LUA_VERSION" xml

# Install the remaining project deps from the rockspec (uses luarocks.lock).
run_luarocks install --lua-version="$LUA_VERSION" \
    --only-deps snapcloud-dev-0.rockspec

echo ">>> Lua dependencies installed."
