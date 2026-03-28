#!/bin/zsh

# Purpose: Report common user cache and log locations that are often safe cleanup candidates.
# Usage: sudo ./macos-cache-log-report.sh [username]
# Notes: This script reports sizes only; it does not delete anything.

set -u

readonly SCRIPT_NAME="$(basename "$0")"

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

get_target_user() {
  if [[ -n "${1:-}" ]]; then
    /bin/echo "$1"
    return 0
  fi

  /usr/bin/stat -f%Su /dev/console
}

get_home_dir() {
  /usr/bin/dscl . -read "/Users/$1" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}'
}

report_top_sizes() {
  local label="$1"
  local path="$2"
  local entries

  if [[ -d "$path" ]]; then
    /bin/echo
    /bin/echo "${label}: ${path}"
    entries=("$path"/*(N))

    if (( ${#entries[@]} == 0 )); then
      /bin/echo "No items found."
      return 0
    fi

    /usr/bin/du -sh "${entries[@]}" 2>/dev/null | /usr/bin/sort -hr | /usr/bin/head -n 10
  else
    /bin/echo
    /bin/echo "${label}: ${path} not found"
  fi
}

main() {
  log "Starting ${SCRIPT_NAME}."

  local target_user home_dir
  target_user="$(get_target_user "${1:-}")"
  home_dir="$(get_home_dir "$target_user")"

  if [[ -z "$home_dir" || ! -d "$home_dir" ]]; then
    /bin/echo "Unable to resolve home directory for user: ${target_user}"
    exit 1
  fi

  /bin/echo "Target User: ${target_user}"
  /bin/echo "Home Directory: ${home_dir}"

  report_top_sizes "User Caches" "${home_dir}/Library/Caches"
  report_top_sizes "User Logs" "${home_dir}/Library/Logs"
  report_top_sizes "Application Support" "${home_dir}/Library/Application Support"
  report_top_sizes "System Logs" "/var/log"

  /bin/echo
  /bin/echo "Cleanup note: items above are report-only candidates; review before deleting anything."
  log "Completed ${SCRIPT_NAME}."
}

main "$@"
