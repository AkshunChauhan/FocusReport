import SwiftUI

@main
struct FocusReportApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar) // Keeps the UI clean
        .windowResizability(.contentSize)
    }
}
