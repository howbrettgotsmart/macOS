#!/bin/zsh

# Purpose: Wrap common softwareupdate actions for Mac Admin maintenance.
# Usage: sudo ./scripts/softwareupdate-maintenance.sh --list|--download|--install
# Notes: `--list` can run without root. Download and install actions require root.

set -u

readonly SCRIPT_NAME="$(basename "$0")"

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    log "This action must be run as root."
    exit 1
  fi
}

usage() {
  cat <<EOF
Usage: ${SCRIPT_NAME} --list|--download|--install
  --list      Show available software updates
  --download  Download all recommended updates
  --install   Install all recommended updates
EOF
}

main() {
  local action="${1:-}"

  case "$action" in
    --list)
      log "Listing available software updates."
      /usr/sbin/softwareupdate --list
      ;;
    --download)
      require_root
      log "Downloading recommended software updates."
      /usr/sbin/softwareupdate --download --all
      ;;
    --install)
      require_root
      log "Installing recommended software updates."
      /usr/sbin/softwareupdate --install --all
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
