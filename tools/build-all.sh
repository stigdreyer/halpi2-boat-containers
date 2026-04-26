#!/bin/bash
# Build all packages: boat-container-store + container apps under apps/.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="${REPO_ROOT}/build"
PREFIX="${PACKAGE_PREFIX:-boat}"

echo "Building all boat packages..."
echo "Repository root: $REPO_ROOT"
echo "Build directory: $BUILD_DIR"
echo "Package prefix:  $PREFIX"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build boat-container-store package
echo ""
echo "=== Building boat-container-store package ==="
cd "${REPO_ROOT}/store"
dpkg-buildpackage -us -uc -b
mv ../boat-container-store_*.deb "$BUILD_DIR/"
mv ../boat-container-store_*.buildinfo "$BUILD_DIR/" 2>/dev/null || true
mv ../boat-container-store_*.changes "$BUILD_DIR/" 2>/dev/null || true

cd "$REPO_ROOT"
rm -f boat-container-store_*.deb boat-container-store_*.buildinfo boat-container-store_*.changes

# Build container app packages using container-packaging-tools.
if command -v uvx >/dev/null 2>&1; then
    echo ""
    echo "=== Building container app packages ==="

    # Determine tools source: local path, git ref, or upstream main branch.
    TOOLS_PATH="${CONTAINER_TOOLS_PATH:-}"
    TOOLS_REF="${CONTAINER_TOOLS_REF:-}"
    if [ -n "$TOOLS_PATH" ]; then
        TOOLS_SOURCE="$TOOLS_PATH"
        echo "Using local container-packaging-tools from: $TOOLS_PATH"
    elif [ -n "$TOOLS_REF" ]; then
        TOOLS_SOURCE="git+https://github.com/halos-org/container-packaging-tools.git@${TOOLS_REF}"
        echo "Using container-packaging-tools ref: $TOOLS_REF"
    else
        TOOLS_SOURCE="git+https://github.com/halos-org/container-packaging-tools.git"
        echo "Using container-packaging-tools from main branch"
    fi

    for app_dir in "${REPO_ROOT}/apps"/*; do
        if [ -d "$app_dir" ]; then
            app_name=$(basename "$app_dir")
            echo "Building package for: $app_name"
            if ! uvx --from "$TOOLS_SOURCE" \
                     generate-container-packages -o "$BUILD_DIR" --prefix "$PREFIX" "$app_dir"; then
                echo "ERROR: Failed to build package for $app_name" >&2
                exit 1
            fi
        fi
    done
else
    echo ""
    echo "WARNING: uvx not installed."
    echo "Install uv: https://docs.astral.sh/uv/getting-started/installation/"
    echo "Skipping container app package generation."
fi

echo ""
echo "=== Built packages ==="
ls -lh "$BUILD_DIR"/*.deb 2>/dev/null || echo "No .deb files found"

echo ""
echo "Build complete. Packages are in: $BUILD_DIR"
