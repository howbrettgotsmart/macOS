#!/bin/bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/Library/Management/AdobeRUMUpdater"
PLIST_LABEL="com.company.adobe-rum-updater"
PLIST_NAME="${PLIST_LABEL}.plist"
LAUNCH_DAEMON_PATH="/Library/LaunchDaemons/${PLIST_NAME}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Re-running with sudo..."
  exec /usr/bin/sudo /bin/bash "$0" "$@"
fi

/bin/mkdir -p "${INSTALL_DIR}" "/var/log/AdobeRUMUpdater"
/usr/sbin/chown root:wheel "${INSTALL_DIR}" "/var/log/AdobeRUMUpdater"
/bin/chmod 755 "${INSTALL_DIR}" "/var/log/AdobeRUMUpdater"

/usr/bin/install -o root -g wheel -m 755 "${SOURCE_DIR}/adobe-rum-updater.sh" "${INSTALL_DIR}/adobe-rum-updater.sh"
/usr/bin/install -o root -g wheel -m 644 "${SOURCE_DIR}/${PLIST_NAME}" "${LAUNCH_DAEMON_PATH}"

if /bin/launchctl print "system/${PLIST_LABEL}" >/dev/null 2>&1; then
  /bin/launchctl bootout system "${LAUNCH_DAEMON_PATH}" >/dev/null 2>&1 || true
fi

/bin/launchctl bootstrap system "${LAUNCH_DAEMON_PATH}"
/bin/launchctl enable "system/${PLIST_LABEL}"

echo "Installed ${PLIST_LABEL}."
echo "To test now: sudo launchctl kickstart -k system/${PLIST_LABEL}"
