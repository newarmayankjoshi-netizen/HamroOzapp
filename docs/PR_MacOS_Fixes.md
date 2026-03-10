PR: macOS build fixes and UX improvements

Summary
- Restores macOS keyboard input (removed app-level RawKeyboard handler).
- Adds prefill helper for Name/Phone/Email and applies to Room/Item/Job/Event forms.
- Adds Guides image asset and updates `FeatureCard` to display it.
- Cleans macOS xcconfigs and removes temporary `-Wl,-w` suppression flags.
- Adds a `post_install` block in `macos/Podfile` to strip explicit `-lc++` occurrences from `OTHER_LDFLAGS` to reduce duplicate linker warnings.

Files changed (high level)
- `macos/Podfile` — post_install cleanup
- `macos/Runner/Configs/{Debug,Release,Profile}.xcconfig` — removed temporary suppression flags
- `lib/utils/user_prefill_helper.dart` — new helper
- `lib/*_page.dart` — applied prefill changes to forms
- `lib/main.dart` — removed global key handler, added Guides asset display
- `pubspec.yaml` — added `assets/guides_card.png` and `guides_card.svg`
- `macos-fixes-commit.patch`, `macos-fix-linker-warnings.patch` — patches
- `docs/MACOS_UPGRADE_NOTES.md` — upgrade notes and remaining warnings

How to push and open PR
1. Add remote (if missing) and push:

```bash
git remote add origin <your-remote-url>
git push -u origin macos-fixes
```

2. Open a Pull Request via GitHub/GitLab UI, or use gh CLI:

```bash
gh pr create --title "macOS: fix linker warnings, restore keyboard, prefill + guides assets" --body-file docs/PR_MacOS_Fixes.md --base main
```

Wrapper script for CI / local installs

To avoid CocoaPods printing the repeated "Invalid key/value pair: DART_DEFINES=..." warnings,
use the provided wrapper which unsets `DART_DEFINES` before running `pod install`.

From the repository root:

```bash
./scripts/pod_install_macos.sh
# or explicitly:
unset DART_DEFINES && pod install --project-directory=macos
```

Add this to CI job steps that run `pod install` for macOS to reduce noisy parsing warnings.

Patch file
The wrapper and related commit are in branch `macos-fixes`; a patch was generated as
`macos-pod-install-wrapper.patch` in the repo root for review.

Notes and follow-ups
- This PR intentionally avoids aggressive package upgrades to minimize runtime/API changes. See `docs/MACOS_UPGRADE_NOTES.md` for recommended package upgrade steps.
- Plugin-level macOS warnings (from Firebase, video_player, gRPC, etc.) remain and should be addressed by upgrading those packages or filing upstream issues.

If you want, I can:
- Attempt one-by-one package upgrades and fix any code/API breakages.
- Try to further narrow the `-lc++` duplicates by inspecting individual pod target build settings and proposing a more targeted `post_install` tweak.
- Create the PR branch remotely if you supply remote URL or grant push access.
