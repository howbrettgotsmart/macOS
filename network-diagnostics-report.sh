#!/bin/zsh

# Purpose: Collect a quick network diagnostics snapshot for Mac Admin troubleshooting.
# Usage: sudo ./network-diagnostics-report.sh
# Notes: This script is report-only and does not change any network settings.

set -u

readonly SCRIPT_NAME="$(basename "$0")"

log() {
  /bin/echo "[$(/bin/date '+%Y-%m-%d %H:%M:%S')] $*"
}

primary_service() {
  /usr/sbin/route get default 2>/dev/null | /usr/bin/awk '/interface:/{print $2; exit}'
}

wifi_device() {
  /usr/sbin/networksetup -listallhardwareports 2>/dev/null | /usr/bin/awk '
    /Hardware Port: Wi-Fi/ { getline; print $2; exit }
  '
}

dns_servers_for_service() {
  local service="$1"
  /usr/sbin/networksetup -getdnsservers "$service" 2>/dev/null
}

main() {
  local interface wifi_port wifi_name ip_address router dns_output

  log "Starting ${SCRIPT_NAME}."

  interface="$(primary_service)"
  wifi_port="$(wifi_device)"
  ip_address="$([ -n "$interface" ] && /usr/sbin/ipconfig getifaddr "$interface" 2>/dev/null || true)"
  router="$(/usr/sbin/route -n get default 2>/dev/null | /usr/bin/awk '/gateway:/{print $2; exit}')"
  wifi_name="$([ -n "$wifi_port" ] && /usr/sbin/networksetup -getairportnetwork "$wifi_port" 2>/dev/null || true)"
  dns_output="$([ -n "$interface" ] && dns_servers_for_service "Wi-Fi" || true)"

  /bin/echo "Hostname: $(/bin/hostname)"
  /bin/echo "Primary Interface: ${interface:-Unavailable}"
  /bin/echo "Primary IP Address: ${ip_address:-Unavailable}"
  /bin/echo "Default Gateway: ${router:-Unavailable}"
  /bin/echo "Wi-Fi Device: ${wifi_port:-Unavailable}"
  /bin/echo "Wi-Fi Network: ${wifi_name:-Unavailable}"
  /bin/echo "DNS Servers:"
  if [[ -n "$dns_output" ]]; then
    /bin/echo "$dns_output"
  else
    /bin/echo "Unavailable"
  fi
  /bin/echo
  /bin/echo "Network Services:"
  /usr/sbin/networksetup -listallnetworkservices 2>/dev/null
  /bin/echo
  /bin/echo "Recent DNS Resolver State:"
  /usr/bin/scutil --dns 2>/dev/null | /usr/bin/head -n 40

  log "Completed ${SCRIPT_NAME}."
}

main "$@"
