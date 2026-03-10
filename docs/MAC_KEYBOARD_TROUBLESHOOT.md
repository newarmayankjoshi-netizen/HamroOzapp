macOS keyboard troubleshooting for Flutter app

Quick checks
- Ensure the app window is focused and not capturing global key events.
- Try typing in other apps to rule out hardware/OS issues.
- Reboot and try a different USB/Bluetooth keyboard if available.

Flutter/macOS-specific checks
- Search for `RawKeyboard` or `KeyboardListener` usage in `lib/` and temporarily disable to confirm focus handling.
- Run the app from Xcode and check Console for messages when typing.
- Ensure accessibility/privacy settings do not block input for the app.

Hardware/service suggestions
- Reset the Mac's SMC/NVRAM if keyboard is unresponsive system-wide.
- For Bluetooth keyboards, unpair and re-pair the device.
- Try safe mode to rule out third-party input managers.

If you'd like, I can:
- Inspect `lib/main.dart` for remaining global key handlers.
- Add a short diagnostic toggle in-app to log RawKeyboard events for debugging.
