#!/bin/bash

###############################################################################
# Slack Updater Script
# Created by Brett Thomason - Sarasota’s Mac Whisperer 😎
# Date: April 5, 2025
#
# This script kills Slack (if "kill" is passed as a parameter), downloads the
# latest version, installs it, sets proper ownership, and disables auto-updates.
###############################################################################

# Kill Slack if parameter 4 is "kill"
killSlack="kill"

# Get the latest version number from Slack's RSS feed
# Handles versions beyond 4.9
currentSlackVersion=$(/usr/bin/curl -sL 'https://slack.com/release-notes/mac/rss' \
    | egrep -o "Slack-[0-9]{1,}\.[0-9]{1,}\.[0-9]{1,}" \
    | cut -d '-' -f2 | head -n1)

# Install Slack function
install_slack() {
    echo "=> Installing Slack $currentSlackVersion..."

    # Resolve the Slack download URL
    slackDownloadUrl=$(curl -sL -I "https://slack.com/ssb/download-osx-universal" -o /dev/null -w '%{url_effective}')
    dmgName=$(basename "$slackDownloadUrl")
    slackDmgPath="/tmp/$dmgName"

    # Kill Slack if required
    if [ "$killSlack" = "kill" ]; then
        echo "=> Killing Slack..."
        killall Slack 2>/dev/null
    fi

    # Download latest Slack
    echo "=> Downloading Slack from $slackDownloadUrl..."
    curl -L -o "$slackDmgPath" "$slackDownloadUrl"

    # Mount the .dmg
    echo "=> Mounting DMG..."
    hdiutil attach -nobrowse "$slackDmgPath"

    # Check and kill Slack if still running
    if pgrep -x "Slack" >/dev/null; then
        echo "=> Slack still running... trying again"
        pkill Slack 2>/dev/null
        sleep 5
        if pgrep -x "Slack" >/dev/null; then
            echo "=> Error: Slack is still running. Please close it manually."
            exit 409
        fi
    fi

    # Remove old version and install new one
    echo "=> Removing existing Slack.app..."
    rm -rf /Applications/Slack.app

    echo "=> Copying new Slack.app..."
    ditto -rsrc /Volumes/Slack*/Slack.app /Applications/Slack.app

    # Unmount and eject DMG
    echo "=> Unmounting DMG..."
    diskutil unmount /Volumes/Slack* >/dev/null
    diskutil eject /Volumes/Slack* >/dev/null 2>&1

    # Clean up temp file
    echo "=> Cleaning up..."
    rm -rf "$slackDmgPath"
}

# Set proper ownership
assimilate_ownership() {
    echo "=> Setting ownership on /Applications/Slack.app..."
    local user=$(scutil <<< "show State:/Users/ConsoleUser" | awk -F': ' '/Name/ && $2 != "loginwindow" { print $2 }')
    chown -R "$user":staff "/Applications/Slack.app"
}

# Disable auto-updates
disable_autoupdate() {
    echo "=> Disabling Slack auto-updates..."
    defaults write com.tinyspeck.slackmacgap SlackNoAutoUpdates -bool YES
}

# Main logic
if [ ! -d "/Applications/Slack.app" ]; then
    echo "=> Slack.app is not installed. Installing fresh..."
    install_slack
    assimilate_ownership
    disable_autoupdate

else
    localSlackVersion=$(defaults read "/Applications/Slack.app/Contents/Info.plist" "CFBundleShortVersionString" 2>/dev/null)

    if [ "$currentSlackVersion" != "$localSlackVersion" ]; then
        echo "=> Slack is outdated (current: $localSlackVersion, latest: $currentSlackVersion)"
        install_slack
        assimilate_ownership
        disable_autoupdate
    else
        echo "=> Slack is already up-to-date (version: $localSlackVersion)"
        assimilate_ownership
        disable_autoupdate
        exit 0
    fi
fi
