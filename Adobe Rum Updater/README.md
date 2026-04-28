# Local Adobe RUM Updater

This package installs a local LaunchDaemon that runs Adobe Remote Update Manager
once per day. It avoids tying up Jamf policy execution while still giving users a
chance to save work before apps are quit for updates.

## What it does

- Runs daily from `launchd` as root.
- Uses Adobe Remote Update Manager at `/usr/local/bin/RemoteUpdateManager`.
- Installs swiftDialog automatically if it is missing.
- Checks whether common interactive Adobe apps are open.
- If no watched Adobe apps are open, runs RUM silently.
- If watched apps are open, shows a swiftDialog prompt with:
  - `Update Now`
  - `Ask Later`
- If the user chooses `Update Now`, the script asks open Adobe apps to quit with
  AppleScript, waits up to five minutes, then runs RUM.
- If the user chooses `Ask Later`, dismisses the prompt, or the prompt times out,
  the script exits cleanly and tries again at the next scheduled run.

## Files

- `adobe-rum-updater.sh`: main updater script.
- `com.company.adobe-rum-updater.plist`: LaunchDaemon definition.
- `install_adobe_rum_updater.sh`: installs the script and LaunchDaemon.
- `uninstall_adobe_rum_updater.sh`: removes the LaunchDaemon and script.
- `jamf_deploy_adobe_rum_updater.sh`: all-in-one Jamf Pro deployment script
  for environments where you do not want to build a package.

## Requirements

- Adobe Remote Update Manager installed at `/usr/local/bin/RemoteUpdateManager`.
- Internet access to GitHub if swiftDialog is not already installed.

If swiftDialog is missing, the script downloads the latest `.pkg` from the
official swiftDialog GitHub releases API and installs it locally. The installer
places the binary at `/usr/local/bin/dialog`.

If swiftDialog cannot be installed and watched Adobe apps are open, the script
skips the run rather than updating underneath the user. If no watched Adobe apps
are open, RUM can still run without swiftDialog.

## Install

```bash
cd "/path/to/adobe-rum-updater"
sudo ./install_adobe_rum_updater.sh
```

The installer copies files to:

```text
/Library/Management/AdobeRUMUpdater
/Library/LaunchDaemons/com.company.adobe-rum-updater.plist
```

## Jamf Pro script-only deployment

Use `jamf_deploy_adobe_rum_updater.sh` when you want to deploy without Composer
or a package.

In Jamf Pro:

1. Go to `Settings > Computer Management > Scripts`.
2. Create a new script and paste in the full contents of
   `jamf_deploy_adobe_rum_updater.sh`.
3. Create a policy scoped to your Adobe Macs.
4. Add the script payload.
5. Set execution frequency to `Once per computer`.
6. Use `Enrollment Complete`, `Recurring Check-in`, or a custom trigger.

The Jamf policy only installs the local LaunchDaemon. The daily Adobe update run
happens later through `launchd`, which keeps Jamf policy execution from being
held open by RUM.

## Test a run

```bash
sudo launchctl kickstart -k system/com.company.adobe-rum-updater
tail -f /var/log/AdobeRUMUpdater/adobe-rum-updater.log
```

## Schedule

The included LaunchDaemon runs daily at 11:30 AM with up to a 90-minute
randomized delay. This means each Mac runs sometime between 11:30 AM and 1:00 PM
local time:

```xml
<key>StartCalendarInterval</key>
<dict>
  <key>Hour</key>
  <integer>11</integer>
  <key>Minute</key>
  <integer>30</integer>
</dict>
<key>RandomizedDelaySec</key>
<integer>5400</integer>
```

Edit `com.company.adobe-rum-updater.plist` before installing if you want a
different time.

## Customize watched apps

Edit `WATCHED_APP_PREFIXES` in `adobe-rum-updater.sh`.

Version-suffixed Adobe app names are matched by prefix, so a base entry such as
`Adobe Photoshop` matches `Adobe Photoshop 2025`.

## Customize RUM behavior

By default the script runs:

```bash
/usr/local/bin/RemoteUpdateManager --action=install
```

Change `RUM_ARGS` in `adobe-rum-updater.sh` if you need product-specific RUM
arguments.
