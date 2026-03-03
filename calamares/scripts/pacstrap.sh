#!/usr/bin/env bash
set -euo pipefail

ROOT_MOUNT="/tmp/calamares-root"
PACKAGES_FILE="/etc/calamares/packages.txt"

# Install all packages from packages.txt into the Calamares target root.
PACKAGES=$(grep -v '^\s*#' "$PACKAGES_FILE" | grep -v '^\s*$' | tr '\n' ' ')

echo "Running pacstrap to $ROOT_MOUNT..."
# shellcheck disable=SC2086
pacstrap "$ROOT_MOUNT" $PACKAGES
