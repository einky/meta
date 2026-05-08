#!/usr/bin/env bash
# Download the pinned Ren'Py SDK, verify its SHA256, and extract it into the
# directory passed as $1. Reads the pin from ../versions.env.
#
# Usage: install-renpy-sdk.sh <target-dir>
#
# Consumed by:
#   - os/stage-sdk      (image build)
#   - runtime/scripts   (dev workstation install; symlinked to this file)
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "usage: $(basename "$0") <target-dir>" >&2
    exit 2
fi

TARGET_DIR="$1"

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
VERSIONS_ENV="$SCRIPT_DIR/../versions.env"

if [ ! -f "$VERSIONS_ENV" ]; then
    echo "error: versions.env not found at $VERSIONS_ENV" >&2
    exit 1
fi

set -a
# shellcheck disable=SC1090
. "$VERSIONS_ENV"
set +a

: "${RENPY_SDK_VERSION:?RENPY_SDK_VERSION not set in versions.env}"
: "${RENPY_SDK_URL:?RENPY_SDK_URL not set in versions.env}"
: "${RENPY_SDK_SHA256:?RENPY_SDK_SHA256 not set in versions.env — run sha256sum on the tarball and fill it in}"

mkdir -p "$TARGET_DIR"
TARGET_DIR=$(cd -- "$TARGET_DIR" &>/dev/null && pwd)

TARBALL_NAME="renpy-${RENPY_SDK_VERSION}-sdk.tar.bz2"
SDK_DIR_NAME="renpy-${RENPY_SDK_VERSION}-sdk"

if [ -d "$TARGET_DIR/$SDK_DIR_NAME" ]; then
    echo "Ren'Py SDK $RENPY_SDK_VERSION already present at $TARGET_DIR/$SDK_DIR_NAME — nothing to do."
    exit 0
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

TARBALL="$WORK/$TARBALL_NAME"

echo "Downloading $RENPY_SDK_URL"
curl -fL --progress-bar -o "$TARBALL" "$RENPY_SDK_URL"

echo "Verifying SHA256..."
ACTUAL=$(sha256sum "$TARBALL" | awk '{print $1}')
if [ "$ACTUAL" != "$RENPY_SDK_SHA256" ]; then
    echo "error: SHA256 mismatch for $TARBALL_NAME" >&2
    echo "  expected: $RENPY_SDK_SHA256" >&2
    echo "  actual:   $ACTUAL" >&2
    exit 1
fi
echo "OK ($ACTUAL)"

echo "Extracting to $TARGET_DIR..."
tar -xjf "$TARBALL" -C "$TARGET_DIR"

echo "Done. Ren'Py SDK $RENPY_SDK_VERSION installed at: $TARGET_DIR/$SDK_DIR_NAME"
