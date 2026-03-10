#!/usr/bin/env bash
set -euo pipefail

# Wrapper to run CocoaPods `pod install` for the macOS project with
# `DART_DEFINES` removed from the environment to reduce Pod parser warnings.

# If running from CI or an environment where DART_DEFINES is set, unset it.
if [ -n "${DART_DEFINES-}" ]; then
  unset DART_DEFINES
fi

pod install --project-directory=macos "$@"
