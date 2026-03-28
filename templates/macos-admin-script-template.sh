#!/bin/zsh

# Purpose: Describe what this script does.
# Usage: sudo ./script-name.sh [optional-args]
# Notes: Add Jamf parameter expectations or prerequisites here when needed.

set -u

readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_TAG="${SCRIPT_NAME:r}"
readonly TEMP_DIR="$(/usr/bin/mktemp -d "/tmp/${LOG_TAG}.XXXXXX")"

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

cleanup() {
  if [[ -d "$TEMP_DIR" ]]; then
    /bin/rm -rf "$TEMP_DIR"
  fi
}

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    log "This script must be run as root."
    exit 1
  fi
}

main() {
  trap cleanup EXIT
  require_root

  log "Starting ${SCRIPT_NAME}."

  # Add task-specific logic here.

  log "Completed ${SCRIPT_NAME}."
}

main "$@"
