#!/usr/bin/env bash
set -euo pipefail

# ─── platform detection ───────────────────────────────────────────────────────
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  RENPY_PLATFORM="py3-linux-x86_64" ;;
    aarch64) RENPY_PLATFORM="py3-linux-aarch64" ;;
    *)
        echo "error: unsupported architecture '$ARCH' (only x86_64 and aarch64 are supported)" >&2
        exit 1
        ;;
esac

# ─── fetch latest release assets ─────────────────────────────────────────────
# The release tag (e.g. 8.5.2.26010301) differs from the SDK filename version
# (e.g. 8.5.2), so we resolve the URL directly from the asset list.
#   x86_64  → renpy-X.Y.Z-sdk.tar.bz2      (not the -sdkarm variant)
#   aarch64 → renpy-X.Y.Z-sdkarm.tar.bz2
echo "Fetching latest Ren'Py release..."
API_RESPONSE=$(curl -fsSL "https://api.github.com/repos/renpy/renpy/releases/latest")

case "$RENPY_PLATFORM" in
    py3-linux-x86_64)
        DOWNLOAD_URL=$(printf '%s' "$API_RESPONSE" \
            | grep '"browser_download_url"' \
            | grep 'renpy-.*-sdk\.tar\.bz2' \
            | grep -v 'sdkarm' \
            | head -1 \
            | sed 's/.*"browser_download_url": *"//;s/".*//')
        ;;
    py3-linux-aarch64)
        DOWNLOAD_URL=$(printf '%s' "$API_RESPONSE" \
            | grep '"browser_download_url"' \
            | grep 'renpy-.*-sdkarm\.tar\.bz2' \
            | head -1 \
            | sed 's/.*"browser_download_url": *"//;s/".*//')
        ;;
esac

if [ -z "$DOWNLOAD_URL" ]; then
    echo "error: could not find SDK download URL in GitHub release assets" >&2
    exit 1
fi

FILENAME=$(basename "$DOWNLOAD_URL")
SDK_VERSION=$(printf '%s' "$FILENAME" | sed 's/renpy-//;s/-sdkarm\.tar\.bz2//;s/-sdk\.tar\.bz2//')
SDK_DIR="renpy-${SDK_VERSION}-sdk"

echo "Latest version: $SDK_VERSION"

# ─── download ─────────────────────────────────────────────────────────────────
if [ -d "$SDK_DIR" ]; then
    echo "SDK directory '$SDK_DIR' already exists — skipping download."
else
    echo "Downloading $FILENAME ..."
    curl -fL --progress-bar -o "$FILENAME" "$DOWNLOAD_URL"

    echo "Extracting..."
    tar xjf "$FILENAME"
    rm "$FILENAME"

    # The arm tarball may extract to renpy-X.Y.Z-sdkarm/ — normalise to -sdk/
    if [ ! -d "$SDK_DIR" ] && [ -d "renpy-${SDK_VERSION}-sdkarm" ]; then
        mv "renpy-${SDK_VERSION}-sdkarm" "$SDK_DIR"
    fi
fi

# ─── strip non-essential content ──────────────────────────────────────────────
echo "Stripping non-essential content..."

# Documentation
rm -rf "$SDK_DIR/doc"

# Demo / sample games (keep launcher — it's the SDK project browser)
rm -rf "$SDK_DIR/the_question" "$SDK_DIR/tutorial"

# Platform-specific lib dirs — keep only what matches this machine.
# Note: lib/python3.* contains the bundled Python stdlib and must be kept on
# every platform (the renpy binary embeds /home/tom/.../lib/python3.X paths
# and resolves them relative to its own location at runtime).
if [ -d "$SDK_DIR/lib" ]; then
    for lib_dir in "$SDK_DIR/lib"/*/; do
        [ -d "$lib_dir" ] || continue
        dir_name=$(basename "$lib_dir")
        case "$dir_name" in
            "$RENPY_PLATFORM"|python3.*)
                ;;
            *)
                echo "  removing lib/$dir_name"
                rm -rf "$lib_dir"
                ;;
        esac
    done
fi

# Windows executables, macOS bundles and disk images
rm -f  "$SDK_DIR"/*.exe
rm -f  "$SDK_DIR"/*.dmg
rm -rf "$SDK_DIR/renpy.app"

# ─── done ─────────────────────────────────────────────────────────────────────
echo ""
echo "Done. SDK ready at: $SDK_DIR"
echo "Platform: $RENPY_PLATFORM"
echo ""
echo "Usage:"
echo "  ./$SDK_DIR/renpy.sh <project_dir>"
