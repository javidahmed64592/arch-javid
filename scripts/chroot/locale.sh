#!/bin/bash
set -euo pipefail

# Variables
LOCALE=
KEYMAP=

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --locale) LOCALE="$2"; shift 2 ;;
    --keymap) KEYMAP="$2"; shift 2 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Validate required variables
if [[ -z "$LOCALE" || -z "$KEYMAP" ]]; then
  echo "Usage: $0 --locale <locale> --keymap <keymap>"
  exit 1
fi

# Generate locale and set keymap
sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
