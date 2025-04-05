#!/bin/zsh

###############################################################################
# Wacom Uninstall Script
# Created by Brett - Sarasota's Mac Management Wizard 😎
# Date: April 5, 2025
#
# This script fully removes all Wacom software, services, launch agents,
# daemons, frameworks, preference panes, and user-specific remnants.
# Tested and tailored for macOS environments.
###############################################################################

echo ""
echo "--------------------------------------------------------"
echo "Getting the currently logged-in user"
echo "--------------------------------------------------------"
echo ""

currentUser=$(/bin/ls -l /dev/console | /usr/bin/awk '{ print $3 }')
currentUserID=$(/usr/bin/id -u "$currentUser")

echo "User: $currentUser"
echo "User ID: $currentUserID"
echo ""

echo "--------------------------------------------------------"
echo "Unload Launch Items and Kill Running Processes"
echo "--------------------------------------------------------"
echo "Killing Wacom-related processes..."

for process in "TabletDriver" "UpgradeHelper" "WacomTabletDriver" "WacomTouchDriver"; do
  /usr/bin/killall -c "$process" 2>/dev/null
done

echo "Booting out launch agents..."
for agent in \
  "com.wacom.DataStoreMgr" \
  "com.wacom.IOManager" \
  "com.wacom.wacomtablet"; do
  /bin/launchctl bootout gui/$currentUserID "/Library/LaunchAgents/$agent.plist" 2>/dev/null
done

/bin/launchctl bootout system "/Library/LaunchDaemons/com.wacom.UpdateHelper.plist" 2>/dev/null

echo ""
echo "--------------------------------------------------------"
echo "Remove Wacom application files and system-level support"
echo "--------------------------------------------------------"
echo ""

pathsToRemove=(
  "/Applications/Wacom Tablet.localized/"
  "/Library/Application Support/Tablet/"
  "/Library/Frameworks/WacomMultiTouch.framework/"
  "/Library/LaunchAgents/com.wacom.DataStoreMgr.plist"
  "/Library/LaunchAgents/com.wacom.IOManager.plist"
  "/Library/LaunchAgents/com.wacom.wacomtablet.plist"
  "/Library/LaunchDaemons/com.wacom.UpdateHelper.plist"
  "/Library/PreferencePanes/WacomTablet.prefpane"
  "/Library/PreferencePanes/WacomCenter.prefpane"
  "/Library/Preferences/Tablet/"
  "/Library/PrivilegedHelperTools/com.wacom.DataStoreMgr.app/"
  "/Library/PrivilegedHelperTools/com.wacom.IOManager.app/"
  "/Library/PrivilegedHelperTools/com.wacom.UpdateHelper.app/"
)

for path in "${pathsToRemove[@]}"; do
  /bin/rm -rf "$path"
done

echo ""
echo "--------------------------------------------------------"
echo "Remove Wacom-related folders from default user template"
echo "--------------------------------------------------------"
echo ""

/bin/rm -rf "/Library/User Template/Non_localized/Library/Group Containers/"
/bin/rm -rf "/Library/User Template/Non_localized/Library/Containers/"

echo ""
echo "--------------------------------------------------------"
echo "Remove Wacom-related files from current user"
echo "--------------------------------------------------------"
echo ""

userDirs=(
  "Application Scripts"
  "Containers"
  "Group Containers"
)

for dir in "${userDirs[@]}"; do
  /bin/rm -rf "/Users/$currentUser/Library/$dir/com.wacom.*"
  /bin/rm -rf "/Users/$currentUser/Library/$dir/EG27766DY7.com.wacom.*"
done

/bin/rm -rf "/Users/$currentUser/Library/Preferences/com.wacom.*"

echo ""
echo "--------------------------------------------------------"
echo "Wacom uninstall complete."
echo "--------------------------------------------------------"
