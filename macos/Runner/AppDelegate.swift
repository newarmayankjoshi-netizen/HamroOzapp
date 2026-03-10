import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    #if DEBUG
    // Keeping the process alive in Debug avoids confusing "Lost connection to device"
    // when the main window is closed during development.
    return false
    #else
    return true
    #endif
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
