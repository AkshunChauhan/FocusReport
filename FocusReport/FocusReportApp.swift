import SwiftUI

@main
struct FocusReportApp: App {
    // Initialize the manager here to trigger permission checks immediately
    @StateObject private var permissionCheck = SessionManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    requestPermissions()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    private func requestPermissions() {
        // Trigger Accessibility permission prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Note: Input Monitoring (Keystrokes) usually prompts the first time
        // the NSEvent monitor is started in SessionManager.
    }
}
