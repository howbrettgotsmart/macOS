#!/bin/zsh

# Purpose: Print a compact Mac inventory snapshot for support or Jamf logging.
# Usage: sudo ./macos-system-inventory.sh
# Notes: This script only reports state; it does not make changes.

set -u

readonly SCRIPT_NAME="$(basename "$0")"

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

main() {
  log "Starting ${SCRIPT_NAME}."

  local hostname computer_name os_version build_version architecture model serial
  local console_user free_space uptime primary_ip

  hostname="$(/bin/hostname)"
  computer_name="$(/usr/sbin/scutil --get ComputerName 2>/dev/null || /bin/echo "Unknown")"
  os_version="$(/usr/bin/sw_vers -productVersion)"
  build_version="$(/usr/bin/sw_vers -buildVersion)"
  architecture="$(/usr/bin/uname -m)"
  model="$(/usr/sbin/sysctl -n hw.model)"
  serial="$(/usr/sbin/ioreg -rd1 -c IOPlatformExpertDevice | /usr/bin/awk -F'"' '/IOPlatformSerialNumber/{print $4; exit}')"
  console_user="$(/usr/bin/stat -f%Su /dev/console)"
  free_space="$(/bin/df -h / | /usr/bin/awk 'NR==2 {print $4}')"
  uptime="$(/usr/bin/uptime | /usr/bin/sed 's/^ *//')"
  primary_ip="$(/usr/sbin/ipconfig getifaddr en0 2>/dev/null || /bin/echo "Unavailable")"

  /bin/echo "Hostname: ${hostname}"
  /bin/echo "Computer Name: ${computer_name}"
  /bin/echo "OS Version: ${os_version} (${build_version})"
  /bin/echo "Architecture: ${architecture}"
  /bin/echo "Model: ${model}"
  /bin/echo "Serial: ${serial}"
  /bin/echo "Console User: ${console_user}"
  /bin/echo "Primary IP: ${primary_ip}"
  /bin/echo "Free Space on /: ${free_space}"
  /bin/echo "Uptime: ${uptime}"

  log "Completed ${SCRIPT_NAME}."
}

main "$@"
