#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
TARGET="${INSTALL_DIR}/cprofile"
SOURCE_URL="${SOURCE_URL:-https://raw.githubusercontent.com/caotin/cprofile/main/bin/cprofile}"

mkdir -p "${INSTALL_DIR}"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

curl -fsSL "${SOURCE_URL}" -o "${tmp}"
chmod 755 "${tmp}"
mv -f "${tmp}" "${TARGET}"
trap - EXIT

printf 'Installed cprofile to %s\n' "${TARGET}"
printf 'Run: %s current\n' "${TARGET}"

case ":${PATH}:" in
  *":${INSTALL_DIR}:"*) ;;
  *)
    printf 'Note: %s is not in PATH. Add it to your shell profile.\n' "${INSTALL_DIR}"
    ;;
esac
