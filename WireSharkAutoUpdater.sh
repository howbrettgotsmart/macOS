#!/bin/zsh

# ---------------------------
# Wireshark Auto-Updater for macOS (ZSH)
# ---------------------------

# User-safe environment
USER_HOME=$(eval echo ~$SUDO_USER)
DOWNLOADS="$USER_HOME/Downloads"
LOGFILE="$USER_HOME/Desktop/wireshark_update.log"
APP_PATH="/Applications/Wireshark.app"

log() {
  echo "[$(date)] $1" | tee -a "$LOGFILE"
}

log "[Start] Starting Wireshark update..."

# Exit if Wireshark not installed
if [[ ! -d "$APP_PATH" ]]; then
  log "Wireshark not installed. Exiting."
  exit 0
fi

# Get installed version
INSTALLED_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist" 2>/dev/null)
log "Installed version: $INSTALLED_VERSION"

# Get latest version and URL from XML feed
XML_FEED="https://www.wireshark.org/update/0/Wireshark/4.0.0/macOS/arm64/en-US/stable.xml"
XML_CONTENT=$(curl -s "$XML_FEED")
LATEST_VERSION=$(echo "$XML_CONTENT" | grep -o 'sparkle:shortVersionString=\"[0-9.]*\"' | sed 's/.*=\"//;s/\"//')
LATEST_URL=$(echo "$XML_CONTENT" | grep -o 'url=\"[^\"]*\"' | sed 's/url=\"//;s/\"//')

if [[ -z "$LATEST_VERSION" || -z "$LATEST_URL" ]]; then
  log "Could not fetch version or URL."
  exit 1
fi

log "Latest version: $LATEST_VERSION"

autoload -Uz is-at-least
if is-at-least "$LATEST_VERSION" "$INSTALLED_VERSION"; then
  log "Wireshark is already up to date."
  exit 0
fi

log "Updating to Wireshark $LATEST_VERSION..."

# Download DMG
DMG_FILENAME=$(basename "$LATEST_URL")
DMG_PATH="$DOWNLOADS/$DMG_FILENAME"
curl -L -o "$DMG_PATH" "$LATEST_URL"

if [[ ! -f "$DMG_PATH" ]]; then
  log "Failed to download DMG."
  exit 1
fi

xattr -d com.apple.quarantine "$DMG_PATH" 2>/dev/null

# Mount DMG
log "Mounting DMG..."
MOUNT_OUTPUT=$(hdiutil attach "$DMG_PATH" -nobrowse)
MOUNTED_PATH=$(echo "$MOUNT_OUTPUT" | grep -o '/Volumes/Wireshark[^\r\n]*' | tail -n 1)
log "Mounted at: $MOUNTED_PATH"

# Quit app if running
if pgrep -xq "Wireshark"; then
  log "Quitting Wireshark..."
  osascript -e 'quit app "Wireshark"'
  sleep 2
fi

# Check new app exists before deleting old one
if [[ -d "$MOUNTED_PATH/Wireshark.app" ]]; then
  log "Found new Wireshark.app in mounted DMG."

  if [[ -d "$APP_PATH" ]]; then
    log "Removing old version..."
    rm -rf "$APP_PATH"
  fi

  log "Copying new version to /Applications..."
  ditto -rsrc "$MOUNTED_PATH/Wireshark.app" "$APP_PATH" || {
    log "Failed to copy Wireshark.app."
    hdiutil detach "$MOUNTED_PATH" >/dev/null 2>&1
    exit 1
  }

else
  log "New Wireshark.app not found in mounted DMG."
  hdiutil detach "$MOUNTED_PATH" >/dev/null 2>&1
  exit 1
fi

# Eject volume
if [[ -n "$MOUNTED_PATH" && -d "$MOUNTED_PATH" ]]; then
  log "Unmounting $MOUNTED_PATH..."
  hdiutil detach "$MOUNTED_PATH" >/dev/null 2>&1
  diskutil eject "$MOUNTED_PATH" >/dev/null 2>&1
else
  log "No valid mount point found to detach."
fi

# Clean up
rm -f "$DMG_PATH"

log "Wireshark successfully updated to $LATEST_VERSION"
exit 0
