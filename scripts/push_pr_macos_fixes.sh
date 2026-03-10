#!/usr/bin/env bash
set -euo pipefail

# Push current branch `macos-fixes` to origin and open a PR via `gh`.
# This script will not force-push and will check for `gh` and remote existence.

BRANCH=macos-fixes
REMOTE=${1:-origin}

if ! git show-ref --verify --quiet refs/heads/$BRANCH; then
  echo "Branch $BRANCH not found locally." >&2
  exit 1
fi

if ! git remote get-url "$REMOTE" >/dev/null 2>&1; then
  echo "Remote '$REMOTE' not found. Add it with: git remote add $REMOTE <url>" >&2
  exit 1
fi

git push --set-upstream "$REMOTE" "$BRANCH"

if command -v gh >/dev/null 2>&1; then
  gh pr create --title "macOS: fix linker warnings, restore keyboard, prefill + guides assets" \
    --body-file docs/PR_MacOS_Fixes.md --base main --head "$REMOTE:$BRANCH"
else
  echo "Pushed branch. Install GitHub CLI (gh) or open a PR via web UI." >&2
fi
