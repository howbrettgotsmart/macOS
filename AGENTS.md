# macOS Script Authoring Guide

This repository is for practical macOS admin shell scripts.

When writing or updating scripts here, follow these rules:

- Prefer `zsh` for new scripts unless POSIX `sh` is clearly the better fit.
- Write for real Mac Admin tasks: app install/update, cleanup, maintenance, preference management, inventory, log collection, LaunchDaemon support, and Jamf-friendly remediation.
- Default to safe behavior. Validate inputs, check privileges when root is required, and avoid destructive actions unless the task explicitly calls for them.
- Make scripts idempotent when possible so rerunning them does not create damage or drift.
- Use readable structure: constants near the top, small functions, a `main` function, and explicit exit codes.
- Use full system paths for key tools when practical, such as `/usr/bin/curl`, `/usr/bin/defaults`, `/usr/sbin/installer`, and `/usr/bin/hdiutil`.
- Prefer clear logging with timestamps. Write logs to stdout at minimum; add file logging only when it materially helps the workflow.
- Clean up temporary files and mounted disk images.
- Add a short header that explains purpose, expected use, and notable parameters.
- Keep comments useful and brief. Explain intent, not obvious shell syntax.
- Favor maintainability over cleverness.

For new scripts, start from `templates/macos-admin-script-template.sh`.

For publishing changes from this repo, use `scripts/publish-script.sh`.
