#!/bin/zsh

# Purpose: Report local admin membership and highlight the current console user.
# Usage: sudo ./local-admin-audit.sh
# Notes: This script is audit-only and does not change local accounts.

set -u

readonly SCRIPT_NAME="$(basename "$0")"

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

console_user() {
  /usr/bin/stat -f%Su /dev/console
}

list_admins() {
  /usr/sbin/dseditgroup -o read admin 2>/dev/null | /usr/bin/awk -F': ' '/GroupMembership/{print $2}'
}

main() {
  local current_user admin_list

  log "Starting ${SCRIPT_NAME}."

  current_user="$(console_user)"
  admin_list="$(list_admins)"

  /bin/echo "Console User: ${current_user}"
  /bin/echo "Local Admin Group Members:"

  if [[ -n "$admin_list" ]]; then
    for user in ${(z)admin_list}; do
      if [[ "$user" == "$current_user" ]]; then
        /bin/echo "  - ${user} (console user)"
      else
        /bin/echo "  - ${user}"
      fi
    done
  else
    /bin/echo "  - No local admin accounts found"
  fi

  /bin/echo
  /bin/echo "Secure Token Status for Console User:"
  /usr/sbin/sysadminctl -secureTokenStatus "$current_user" 2>&1 || true

  log "Completed ${SCRIPT_NAME}."
}

main "$@"
