import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var manager = SessionManager()
    
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: mainDashboard) {
                    Label("Dashboard", systemImage: "clock")
                }
                NavigationLink(destination: supportSection) {
                    Label("Support", systemImage: "questionmark.circle")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Work Portal")
        } detail: {
            mainDashboard
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - Simplified Employee Dashboard
    private var mainDashboard: some View {
        VStack(spacing: 40) {
            VStack(spacing: 12) {
                Text(manager.isTracking ? "Session Active" : "Ready to Start")
                    .font(.title).bold()
            }
            
            HStack(spacing: 20) {
                if !manager.isTracking {
                    Button(action: { manager.start() }) {
                        Text("Start Work Session")
                            .frame(width: 200, height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else {
                    Button(action: {
                        if manager.isPaused {
                            manager.resume()
                        } else {
                            manager.pause()
                        }
                    }) {
                        Label(manager.isPaused ? "Resume" : "Pause", systemImage: manager.isPaused ? "play.fill" : "pause.fill")
                            .frame(width: 120, height: 40)
                    }
                    .buttonStyle(.bordered)
                    .tint(manager.isPaused ? .green : .orange)
                    
                    Button(action: { manager.stop() }) {
                        Label("End & Submit", systemImage: "checkmark.circle.fill")
                            .frame(width: 140, height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            
            VStack(spacing: 8) {
                HStack {
                    Circle()
                        .fill(manager.isPaused ? .orange : (manager.isTracking ? .green : .gray))
                        .frame(width: 10, height: 10)
                    Text(manager.isPaused ? "Status: Paused" : (manager.isTracking ? "Status: Recording" : "Status: Idle"))
                        .font(.subheadline).foregroundColor(.secondary)
                }
                
                if manager.isTracking {
                    Text("Auto-saving progress...")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(50)
        .animation(.spring(), value: manager.isTracking)
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Support & Documentation")
                .font(.title).bold()
            
            Text("If you encounter any issues with the work portal, please contact your administrator.")
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("System Information")
                .font(.headline)
            Text("Version: 2.1.0 (Stable)")
            Text("Last Sync: \(Date().formatted())")
            
            Spacer()
        }
        .padding()
    }
    
}
