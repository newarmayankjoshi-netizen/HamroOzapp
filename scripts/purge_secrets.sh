#!/usr/bin/env bash
set -euo pipefail

# Safe, local-only git history cleaner for this repo.
# Creates a timestamped mirror clone, runs git-filter-repo to remove
# known sensitive files, and performs garbage collection.
# It DOES NOT push changes to any remote; pushing must be done manually.

REPO_PATH="/Users/nagma/Nepali-Help/nepal_australia_app"
BACKUP_DIR="$HOME/repo-backup-$(date +%Y%m%d-%H%M%S).git"

echo "Creating mirror clone of $REPO_PATH -> $BACKUP_DIR"
git clone --mirror "$REPO_PATH" "$BACKUP_DIR"
cd "$BACKUP_DIR"

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "git-filter-repo not found; installing via pip (user)"
  python3 -m pip install --user git-filter-repo
  export PATH="$HOME/.local/bin:$PATH"
fi

echo "Running git-filter-repo to remove sensitive files (local-only)..."
# Adjust the paths list below if you want to remove additional files.
git filter-repo \
  --invert-paths \
  --paths nepalese-in-australia-firebase-adminsdk-fbsvc-f81187669d.json \
  --paths serviceAccount.json \
  --paths functions/serviceAccountKey.json \
  --force

echo "Cleaning up refs and garbage collecting"
git reflog expire --expire=now --all || true
git gc --prune=now --aggressive || true

echo
echo "CLEAN MIRROR CREATED: $BACKUP_DIR"
echo
echo "To review changes locally, you can inspect the mirror. To push the cleaned history to your remote 'origin', run:" 
echo "  cd '$BACKUP_DIR'"
echo "  git remote -v"
echo "  # ensure 'origin' points to the remote you want to overwrite"
echo "  git push --force --all origin"
echo "  git push --force --tags origin"

echo
echo "IMPORTANT: Do NOT push until you have rotated any exposed credentials and coordinated with collaborators."
