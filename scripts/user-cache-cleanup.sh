#!/bin/zsh

# Purpose: Review and optionally clean common user cache and log locations.
# Usage: sudo ./scripts/user-cache-cleanup.sh [--apply] [username]
# Notes: Default mode is dry-run. Use --apply to remove files from the target user's cache and log folders.

set -u

readonly SCRIPT_NAME="$(basename "$0")"
APPLY_CHANGES="false"
TARGET_USER=""

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

console_user() {
  /usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | /usr/bin/awk -F': ' '/Name/ && $2 != "loginwindow" { print $2 }'
}

require_root() {
  if [[ "$EUID" -ne 0 ]]; then
    log "This script must be run as root."
    exit 1
  fi
}

resolve_target_user() {
  if [[ -n "${TARGET_USER}" ]]; then
    /bin/echo "$TARGET_USER"
    return
  fi

  console_user
}

home_for_user() {
  /usr/bin/dscl . -read "/Users/$1" NFSHomeDirectory 2>/dev/null | /usr/bin/awk '{print $2}'
}

report_size() {
  local path="$1"
  if [[ -d "$path" ]]; then
    /usr/bin/du -sh "$path" 2>/dev/null | /usr/bin/awk '{print $1}'
  else
    /bin/echo "missing"
  fi
}

clean_path() {
  local path="$1"
  if [[ "$APPLY_CHANGES" == "true" && -d "$path" ]]; then
    /bin/rm -rf "${path:?}/"*
    log "Removed contents of $path"
  fi
}

main() {
  local argument
  local effective_user
  local home_dir
  local cache_dir
  local log_dir

  for argument in "$@"; do
    case "$argument" in
      --apply)
        APPLY_CHANGES="true"
        ;;
      *)
        if [[ -z "$TARGET_USER" ]]; then
          TARGET_USER="$argument"
        else
          log "Unexpected argument: $argument"
          exit 1
        fi
        ;;
    esac
  done

  require_root
  effective_user="$(resolve_target_user)"

  if [[ -z "$effective_user" ]]; then
    log "Unable to determine target user."
    exit 1
  fi

  home_dir="$(home_for_user "$effective_user")"
  if [[ -z "$home_dir" || ! -d "$home_dir" ]]; then
    log "Home directory not found for $effective_user."
    exit 1
  fi

  cache_dir="${home_dir}/Library/Caches"
  log_dir="${home_dir}/Library/Logs"

  log "Target user: $effective_user"
  log "Cache size before: $(report_size "$cache_dir")"
  log "Log size before: $(report_size "$log_dir")"

  if [[ "$APPLY_CHANGES" == "true" ]]; then
    clean_path "$cache_dir"
    clean_path "$log_dir"
    log "Cache size after: $(report_size "$cache_dir")"
    log "Log size after: $(report_size "$log_dir")"
  else
    log "Dry-run only. Re-run with --apply to remove cache and log contents."
  fi
}

main "$@"
