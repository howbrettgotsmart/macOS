#!/bin/bash
set -euo pipefail

PLIST_LABEL="com.company.adobe-rum-updater"
PLIST_PATH="/Library/LaunchDaemons/${PLIST_LABEL}.plist"
INSTALL_DIR="/Library/Management/AdobeRUMUpdater"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Re-running with sudo..."
  exec /usr/bin/sudo /bin/bash "$0" "$@"
fi

if /bin/launchctl print "system/${PLIST_LABEL}" >/dev/null 2>&1; then
  /bin/launchctl bootout system "${PLIST_PATH}" >/dev/null 2>&1 || true
fi

/bin/rm -f "${PLIST_PATH}"
/bin/rm -rf "${INSTALL_DIR}"

echo "Uninstalled ${PLIST_LABEL}."
