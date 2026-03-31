#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
TARGET="${INSTALL_DIR}/cprofile"

mkdir -p "${INSTALL_DIR}"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

cat > "${tmp}" <<'CPROFILE_EOF'
#!/usr/bin/env bash

set -euo pipefail

SELF_NAME="${0##*/}"
PROFILE_ROOT="${HOME}/.claude-profiles"
CONFIG_ROOT="${XDG_CONFIG_HOME:-${HOME}/.config}/claude-profile-switch"
ACTIVE_FILE="${CONFIG_ROOT}/active"
ACTIVE_LINK="${HOME}/.claude"
DEFAULT_PROFILE="default"

usage() {
  cat <<EOF
Usage:
  ${SELF_NAME} list
  ${SELF_NAME} current
  ${SELF_NAME} add <name>
  ${SELF_NAME} use [--force] <name>
  ${SELF_NAME} login [--force] <name> [-- <claude auth login args...>]

Commands:
  list       List saved Claude profiles.
  current    Print the active Claude profile name.
  add        Create an empty Claude profile directory.
  use        Switch plain 'claude' to the selected profile.
  login      Switch to a profile and run 'claude auth login'.

Options:
  --force    Allow switching even if another Claude process is running.
EOF
}

die() {
  printf '%s\n' "error: $*" >&2
  exit 1
}

note() {
  printf '%s\n' "$*"
}

ensure_dirs() {
  mkdir -p "${PROFILE_ROOT}" "${CONFIG_ROOT}"
}

validate_name() {
  local name="$1"
  [[ "${name}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "invalid profile name '${name}'"
}

profile_path() {
  printf '%s/%s' "${PROFILE_ROOT}" "$1"
}

write_active() {
  local name="$1"
  local tmp="${ACTIVE_FILE}.tmp.$$"
  printf '%s\n' "${name}" > "${tmp}"
  mv -f "${tmp}" "${ACTIVE_FILE}"
}

active_from_state() {
  [[ -f "${ACTIVE_FILE}" ]] || return 1
  tr -d '\r\n' < "${ACTIVE_FILE}"
}

active_from_link() {
  local target
  [[ -L "${ACTIVE_LINK}" ]] || return 1
  target="$(readlink "${ACTIVE_LINK}")"
  [[ "${target}" == "${PROFILE_ROOT}/"* ]] || return 1
  basename "${target}"
}

current_profile() {
  local from_state from_link
  from_state="$(active_from_state || true)"
  from_link="$(active_from_link || true)"

  if [[ -n "${from_state}" && -n "${from_link}" && "${from_state}" != "${from_link}" ]]; then
    die "active profile state does not match ~/.claude symlink"
  fi

  if [[ -n "${from_state}" ]]; then
    printf '%s\n' "${from_state}"
    return 0
  fi

  if [[ -n "${from_link}" ]]; then
    printf '%s\n' "${from_link}"
    return 0
  fi

  return 1
}

claude_running() {
  pgrep -fl '(^|/)claude($| )' >/dev/null 2>&1
}

require_not_running() {
  local force="${1:-0}"
  if [[ "${force}" != "1" ]] && claude_running; then
    die "another Claude process is running; close it first or rerun with --force"
  fi
}

ensure_profile_exists() {
  local name="$1"
  local path
  path="$(profile_path "${name}")"
  [[ -d "${path}" ]] || die "profile '${name}' does not exist"
}

ensure_link_healthy() {
  local name="$1"
  local target
  target="$(profile_path "${name}")"

  if [[ -L "${ACTIVE_LINK}" && ! -e "${ACTIVE_LINK}" ]]; then
    die "~/.claude points to a missing profile"
  fi

  if [[ -e "${ACTIVE_LINK}" && ! -L "${ACTIVE_LINK}" ]]; then
    die "~/.claude is not a symlink; repair it manually or rerun bootstrap"
  fi

  [[ -d "${target}" ]] || die "active profile '${name}' is missing"
}

bootstrap_if_needed() {
  ensure_dirs

  if [[ -L "${ACTIVE_LINK}" ]]; then
    local active
    active="$(current_profile || true)"
    [[ -n "${active}" ]] || die "~/.claude is a symlink outside ${PROFILE_ROOT}"
    ensure_link_healthy "${active}"
    write_active "${active}"
    return 0
  fi

  if [[ -e "${ACTIVE_LINK}" ]]; then
    local seed_path
    seed_path="$(profile_path "${DEFAULT_PROFILE}")"
    [[ ! -e "${seed_path}" ]] || die "cannot bootstrap: ${seed_path} already exists"
    mv "${ACTIVE_LINK}" "${seed_path}"
    ln -s "${seed_path}" "${ACTIVE_LINK}"
    write_active "${DEFAULT_PROFILE}"
    return 0
  fi

  if [[ -f "${ACTIVE_FILE}" ]]; then
    local active
    active="$(active_from_state || true)"
    [[ -n "${active}" ]] || die "active profile state file is empty"
    ensure_profile_exists "${active}"
    ln -s "$(profile_path "${active}")" "${ACTIVE_LINK}"
    return 0
  fi

  mkdir -p "$(profile_path "${DEFAULT_PROFILE}")"
  ln -s "$(profile_path "${DEFAULT_PROFILE}")" "${ACTIVE_LINK}"
  write_active "${DEFAULT_PROFILE}"
}

switch_profile() {
  local name="$1"
  local current path

  validate_name "${name}"
  ensure_profile_exists "${name}"
  current="$(current_profile || true)"
  path="$(profile_path "${name}")"

  if [[ "${current}" == "${name}" && -L "${ACTIVE_LINK}" && "$(readlink "${ACTIVE_LINK}")" == "${path}" ]]; then
    note "${name}"
    return 0
  fi

  if [[ -e "${ACTIVE_LINK}" && ! -L "${ACTIVE_LINK}" ]]; then
    die "~/.claude is not a symlink; refusing to overwrite it"
  fi

  rm -f "${ACTIVE_LINK}"
  ln -s "${path}" "${ACTIVE_LINK}"
  write_active "${name}"
  note "${name}"
}

cmd_list() {
  local current
  bootstrap_if_needed
  current="$(current_profile || true)"

  shopt -s nullglob
  local found=0
  local path name
  for path in "${PROFILE_ROOT}"/*; do
    [[ -d "${path}" ]] || continue
    found=1
    name="$(basename "${path}")"
    if [[ "${name}" == "${current}" ]]; then
      printf '* %s\n' "${name}"
    else
      printf '  %s\n' "${name}"
    fi
  done
  shopt -u nullglob

  [[ "${found}" -eq 1 ]] || note "no profiles"
}

cmd_current() {
  bootstrap_if_needed
  current_profile
}

cmd_add() {
  local name="${1:-}"
  [[ $# -eq 1 && -n "${name}" ]] || die "usage: ${SELF_NAME} add <name>"
  bootstrap_if_needed
  validate_name "${name}"

  local path
  path="$(profile_path "${name}")"
  [[ ! -e "${path}" ]] || die "profile '${name}' already exists"
  mkdir -p "${path}"
  note "${name}"
}

cmd_use() {
  local force=0
  local name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        force=1
        shift
        ;;
      *)
        [[ -z "${name}" ]] || die "usage: ${SELF_NAME} use [--force] <name>"
        name="$1"
        shift
        ;;
    esac
  done

  [[ -n "${name}" ]] || die "usage: ${SELF_NAME} use [--force] <name>"
  bootstrap_if_needed
  require_not_running "${force}"
  switch_profile "${name}"
}

cmd_login() {
  local force=0
  local name=""
  local -a login_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --force)
        force=1
        shift
        ;;
      --)
        shift
        login_args=("$@")
        break
        ;;
      *)
        if [[ -z "${name}" ]]; then
          name="$1"
          shift
        else
          die "unexpected argument '$1'"
        fi
        ;;
    esac
  done

  [[ -n "${name}" ]] || die "missing profile name"
  bootstrap_if_needed
  validate_name "${name}"
  require_not_running "${force}"

  if [[ ! -d "$(profile_path "${name}")" ]]; then
    mkdir -p "$(profile_path "${name}")"
  fi

  switch_profile "${name}" >/dev/null

  command -v claude >/dev/null 2>&1 || die "claude command not found on PATH"
  if [[ ${#login_args[@]} -gt 0 ]]; then
    exec claude auth login "${login_args[@]}"
  fi

  exec claude auth login
}

main() {
  local cmd="${1:-}"
  case "${cmd}" in
    list)
      shift
      [[ $# -eq 0 ]] || die "list does not accept arguments"
      cmd_list
      ;;
    current)
      shift
      [[ $# -eq 0 ]] || die "current does not accept arguments"
      cmd_current
      ;;
    add)
      shift
      cmd_add "$@"
      ;;
    use)
      shift
      cmd_use "$@"
      ;;
    login)
      shift
      cmd_login "$@"
      ;;
    -h|--help|help|"")
      usage
      ;;
    *)
      die "unknown command '${cmd}'"
      ;;
  esac
}

main "$@"
CPROFILE_EOF

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
