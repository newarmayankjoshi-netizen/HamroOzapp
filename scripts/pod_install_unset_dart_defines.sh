#!/usr/bin/env bash
set -euo pipefail
# Unset DART_DEFINES to avoid CocoaPods env parsing noise
unset DART_DEFINES
# Move to macos dir and run pod install
cd "$(dirname "$0")/../macos" || exit 1
if command -v pod >/dev/null 2>&1; then
  pod install --repo-update
else
  echo "CocoaPods (pod) not found in PATH. Install CocoaPods or run pod install manually."
  exit 1
fi
