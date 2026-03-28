#!/bin/zsh

set -euo pipefail

if [[ $# -lt 2 ]]; then
  /bin/echo "Usage: $0 <path-to-script-or-file> <commit-message>"
  exit 1
fi

TARGET_PATH="$1"
shift
COMMIT_MESSAGE="$*"

if [[ ! -e "$TARGET_PATH" ]]; then
  /bin/echo "File not found: $TARGET_PATH"
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

git add "$TARGET_PATH"
git commit -m "$COMMIT_MESSAGE"
git push origin "$(git branch --show-current)"
