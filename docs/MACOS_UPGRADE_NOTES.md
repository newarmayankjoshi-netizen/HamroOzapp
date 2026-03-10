macOS build + plugin upgrade notes

Summary
- Created local branch `macos-fixes` and committed macOS-related fixes (keyboard handler removal, prefill helper, Guides assets, Podfile `post_install` cleanup, xcconfig tidy).
- Ran `flutter pub upgrade` + `flutter pub upgrade --major-versions` and `pod install`.
- Built macOS app locally; build succeeds and app launches, but several build-time warnings remain.

Remaining notable warnings
- Repeated linker notes: "ignoring duplicate libraries: '-lc++'" (reduced but some duplicates persist, `-lz` combined once). Patch added to `macos/Podfile` strips explicit `-lc++` from `OTHER_LDFLAGS` per-target, which removed most duplicates. If this persists, plugin podspecs may be adding `-lc++` explicitly and require upstream fixes.
- Plugin-level compiler warnings (macOS): many come from Firebase plugins (`firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`) and `video_player_avfoundation`. Types: deprecated API usage, non-exhaustive Swift switches, incompatible pointer types, unused variables. These are in plugin source and will require upstream updates or package bumps.
- CocoaPods "Invalid key/value pair: DART_DEFINES=..." messages during `pod install` — benign; coming from env-var encoding in the build environment.
- Xcode warnings about script phases running every build — cosmetic; consider adding outputs or disabling dependency analysis for those phases.

Recommended next steps
1. Upgrade packages that are safe to bump in `pubspec.yaml` (resolve any SDK or API breaks). Prioritize:
   - `firebase_*` packages to the latest compatible releases (check `flutterfire` changelogs for breaking changes on macOS).
   - `video_player` and related AVFoundation plugin.
   - `google_maps_flutter` and other transitive packages reported by `flutter pub outdated`.
2. After pub upgrades, run:
   ```bash
   flutter pub get
   pod install --project-directory=macos
   flutter clean
   flutter build macos
   ```
3. If `-lc++` duplicate warnings remain, inspect `Pods/` podspecs and `OTHER_LDFLAGS` entries to find which pod(s) add `-lc++` explicitly and open upstream issues or create a targeted `post_install` to only modify those pods.
4. For plugin warnings originating in plugin code, either:
   - Update the plugin (preferred), or
   - Patch vendor code in `macos/Pods/` as a temporary workaround (not recommended long-term).
5. Open a PR from branch `macos-fixes` including `macos-fix-linker-warnings.patch` and `macos-fixes-commit.patch` for review. Include these notes in the PR description.

How to create PR (locally)
- Add a remote and push branch:
  ```bash
  git remote add origin <your-remote-url>
  git push -u origin macos-fixes
  ```
- Create PR via GitHub/GitLab UI or CLI.

Files of interest
- `macos/Podfile` (post_install removal of `-lc++`)
- `macos/Runner/Configs/Debug.xcconfig`, `Release.xcconfig`, `Profile.xcconfig` (cleaned temporary flags)
- `macos-fix-linker-warnings.patch` and `macos-fixes-commit.patch`
- `docs/MACOS_UPGRADE_NOTES.md` (this file)

If you want, I can now:
- Attempt safe package bumps one-by-one and fix resulting API errors.
- Prepare a PR description and attach `macos-fixes-commit.patch` and these notes.
- Try to identify the exact pod(s) still adding `-lc++` and propose a minimal `post_install` adjustment.

