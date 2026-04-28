#!/bin/bash
set -u

SCRIPT_NAME="AdobeRUMUpdater"
LOG_DIR="/var/log/${SCRIPT_NAME}"
LOG_FILE="${LOG_DIR}/adobe-rum-updater.log"
STATE_DIR="/Library/Application Support/${SCRIPT_NAME}"
LAST_DEFERRAL_FILE="${STATE_DIR}/last_deferral_epoch"

RUM_BIN="/usr/local/bin/RemoteUpdateManager"
SWIFT_DIALOG_RELEASE_API="https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest"
DIALOG_BIN_CANDIDATES=(
  "/usr/local/bin/dialog"
  "/Library/Application Support/Dialog/Dialog.app/Contents/MacOS/Dialog"
)

# Base process names. Version-suffixed Adobe apps such as "Adobe Photoshop 2025"
# are matched by prefix, so this list does not need yearly maintenance.
WATCHED_APP_PREFIXES=(
  "Adobe Acrobat"
  "Adobe After Effects"
  "Adobe Audition"
  "Adobe Bridge"
  "Adobe Character Animator"
  "Adobe Dreamweaver"
  "Adobe Illustrator"
  "Adobe InCopy"
  "Adobe InDesign"
  "Adobe Lightroom Classic"
  "Adobe Media Encoder"
  "Adobe Photoshop"
  "Adobe Premiere Pro"
  "Adobe XD"
)

PROMPT_TITLE="Adobe updates are ready"
PROMPT_MESSAGE=$'Adobe needs to update one or more apps that are currently open.\n\nPlease save your work. Choose Update Now when you are ready, and the open Adobe apps will be asked to quit before updates begin.'
PROMPT_TIMEOUT_SECONDS=900
QUIT_WAIT_SECONDS=300

RUM_ARGS=("--action=install")

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

setup_logging() {
  /bin/mkdir -p "${LOG_DIR}" "${STATE_DIR}"
  /usr/sbin/chown root:wheel "${LOG_DIR}" "${STATE_DIR}"
  /bin/chmod 755 "${LOG_DIR}" "${STATE_DIR}"
  /usr/bin/touch "${LOG_FILE}"
  /bin/chmod 644 "${LOG_FILE}"
  exec >>"${LOG_FILE}" 2>&1
}

console_user() {
  /usr/bin/stat -f '%Su' /dev/console 2>/dev/null
}

console_uid() {
  local user="$1"
  /usr/bin/id -u "${user}" 2>/dev/null
}

run_as_console_user() {
  local user uid
  user="$(console_user)"

  if [[ -z "${user}" || "${user}" == "root" || "${user}" == "loginwindow" ]]; then
    return 1
  fi

  uid="$(console_uid "${user}")" || return 1
  /bin/launchctl asuser "${uid}" /usr/bin/sudo -u "${user}" "$@"
}

dialog_bin() {
  local candidate
  for candidate in "${DIALOG_BIN_CANDIDATES[@]}"; do
    if [[ -x "${candidate}" ]]; then
      /bin/echo "${candidate}"
      return 0
    fi
  done
  return 1
}

latest_swift_dialog_pkg_url() {
  local release_json

  release_json="$(/usr/bin/curl --fail --location --silent --show-error --retry 3 "${SWIFT_DIALOG_RELEASE_API}")" || return 1
  /bin/echo "${release_json}" | /usr/bin/awk -F '"' '/browser_download_url/ && /\.pkg"/ { print $4; exit }'
}

install_swift_dialog() {
  local pkg_url tmp_dir pkg_path installed_dialog_bin

  if dialog_bin >/dev/null 2>&1; then
    return 0
  fi

  log "swiftDialog is not installed. Attempting install from GitHub releases."

  pkg_url="$(latest_swift_dialog_pkg_url)"
  if [[ -z "${pkg_url}" ]]; then
    log "Unable to determine latest swiftDialog package URL."
    return 1
  fi

  tmp_dir="$(/usr/bin/mktemp -d "/private/tmp/${SCRIPT_NAME}.swiftDialog.XXXXXX")" || return 1
  pkg_path="${tmp_dir}/swiftDialog.pkg"

  if ! /usr/bin/curl --fail --location --silent --show-error --retry 3 --output "${pkg_path}" "${pkg_url}"; then
    log "Failed to download swiftDialog package from ${pkg_url}."
    /bin/rm -rf "${tmp_dir}"
    return 1
  fi

  log "Installing swiftDialog package from ${pkg_url}."
  if ! /usr/sbin/installer -pkg "${pkg_path}" -target /; then
    log "swiftDialog package installation failed."
    /bin/rm -rf "${tmp_dir}"
    return 1
  fi

  /bin/rm -rf "${tmp_dir}"

  if installed_dialog_bin="$(dialog_bin)"; then
    log "swiftDialog installed successfully at ${installed_dialog_bin}."
    return 0
  fi

  log "swiftDialog installation completed, but no dialog binary was found."
  return 1
}

running_watched_apps() {
  local command_path app_name watched_prefix

  while IFS= read -r command_path; do
    [[ -z "${command_path}" ]] && continue
    app_name="$(/usr/bin/basename "${command_path}")"

    for watched_prefix in "${WATCHED_APP_PREFIXES[@]}"; do
      if [[ "${app_name}" == "${watched_prefix}" || "${app_name}" == "${watched_prefix} "* ]]; then
        /bin/echo "${app_name}"
        break
      fi
    done
  done < <(/bin/ps -axo comm=) | /usr/bin/sort -u
}

show_update_prompt() {
  local dialog_bin_path="$1"
  local running_apps="$2"
  local app_list dialog_message

  app_list="$(/bin/echo "${running_apps}" | /usr/bin/sed 's/^/- /')"
  dialog_message="${PROMPT_MESSAGE}"$'\n\nCurrently open:\n'"${app_list}"

  run_as_console_user "${dialog_bin_path}" \
    --title "${PROMPT_TITLE}" \
    --message "${dialog_message}" \
    --icon "SF=arrow.triangle.2.circlepath.circle.fill,weight=semibold" \
    --button1text "Update Now" \
    --button2text "Ask Later" \
    --timer "${PROMPT_TIMEOUT_SECONDS}" \
    --ontop \
    --moveable
}

record_deferral() {
  /bin/date '+%s' >"${LAST_DEFERRAL_FILE}"
  /bin/chmod 644 "${LAST_DEFERRAL_FILE}"
  log "User deferred Adobe updates."
}

quit_apps_gracefully() {
  local running_apps="$1"
  local app_name

  while IFS= read -r app_name; do
    [[ -z "${app_name}" ]] && continue
    log "Requesting graceful quit for ${app_name}."
    run_as_console_user /usr/bin/osascript -e "tell application \"${app_name}\" to quit" >/dev/null 2>&1 || true
  done <<<"${running_apps}"
}

wait_for_apps_to_quit() {
  local start_epoch now_epoch remaining_apps
  start_epoch="$(/bin/date '+%s')"

  while true; do
    remaining_apps="$(running_watched_apps || true)"
    if [[ -z "${remaining_apps}" ]]; then
      log "Watched Adobe apps are closed."
      return 0
    fi

    now_epoch="$(/bin/date '+%s')"
    if (( now_epoch - start_epoch >= QUIT_WAIT_SECONDS )); then
      log "Timed out waiting for Adobe apps to quit: ${remaining_apps//$'\n'/, }"
      return 1
    fi

    /bin/sleep 5
  done
}

notify_quit_timeout() {
  local dialog_bin_path="$1"
  local remaining_apps="$2"
  local app_list
  app_list="$(/bin/echo "${remaining_apps}" | /usr/bin/sed 's/^/- /')"

  run_as_console_user "${dialog_bin_path}" \
    --title "Adobe updates paused" \
    --message $'Adobe updates could not start because these apps are still open:\n\n'"${app_list}"$'\n\nPlease save your work and close them. Updates will try again during the next run.' \
    --icon "SF=exclamationmark.triangle.fill,weight=semibold" \
    --button1text "OK" \
    --timer 300 \
    --ontop \
    --moveable >/dev/null 2>&1 || true
}

run_rum() {
  if [[ ! -x "${RUM_BIN}" ]]; then
    log "RemoteUpdateManager not found or not executable at ${RUM_BIN}."
    return 127
  fi

  log "Starting Adobe RemoteUpdateManager: ${RUM_BIN} ${RUM_ARGS[*]}"
  "${RUM_BIN}" "${RUM_ARGS[@]}"
  local exit_code=$?
  log "Adobe RemoteUpdateManager finished with exit code ${exit_code}."
  return "${exit_code}"
}

main() {
  local running_apps dialog_bin_path prompt_exit remaining_apps

  if [[ "${EUID}" -ne 0 ]]; then
    /bin/echo "This script must run as root."
    exit 1
  fi

  setup_logging
  log "Starting local Adobe RUM update run."

  install_swift_dialog || log "swiftDialog could not be installed during this run."

  running_apps="$(running_watched_apps || true)"

  if [[ -n "${running_apps}" ]]; then
    log "Watched Adobe apps are running: ${running_apps//$'\n'/, }"

    if ! dialog_bin_path="$(dialog_bin)"; then
      log "swiftDialog is not installed. Skipping update while watched apps are open."
      exit 0
    fi

    show_update_prompt "${dialog_bin_path}" "${running_apps}"
    prompt_exit=$?

    if [[ "${prompt_exit}" -ne 0 ]]; then
      record_deferral
      exit 0
    fi

    quit_apps_gracefully "${running_apps}"
    if ! wait_for_apps_to_quit; then
      remaining_apps="$(running_watched_apps || true)"
      notify_quit_timeout "${dialog_bin_path}" "${remaining_apps}"
      exit 0
    fi
  else
    log "No watched Adobe apps are open."
  fi

  run_rum
}

main "$@"
