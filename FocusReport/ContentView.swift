import SwiftUI

struct ContentView: View {
    @StateObject private var manager = SessionManager()
    
    var body: some View {
        NavigationSplitView {
            // SIDEBAR: Navigation Table
            List {
                NavigationLink(destination: trackerDashboard) {
                    Label("Work Tracker", systemImage: "clock.badge.checkmark")
                }
                NavigationLink(destination: aboutSection) {
                    Label("About & Help", systemImage: "info.circle")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("XUN Innovation")
        } detail: {
            // Default view when the app opens
            trackerDashboard
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    // MARK: - 1. TRACKER DASHBOARD (The Main Work Table)
    private var trackerDashboard: some View {
        VStack(spacing: 30) {
            VStack(spacing: 8) {
                Text("Operational Dashboard")
                    .font(.title2).bold()
                Text("Ensure your status is ACTIVE during working hours.")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            
            // Visual Status Card
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.05))
                    .frame(height: 100)
                
                HStack(spacing: 20) {
                    Circle()
                        .fill(manager.isPaused ? .orange : (manager.isTracking ? .red : .gray))
                        .frame(width: 12, height: 12)
                        .shadow(color: manager.isTracking ? .red.opacity(0.5) : .clear, radius: 4)
                    
                    VStack(alignment: .leading) {
                        Text(manager.isPaused ? "STATUS: PAUSED" : (manager.isTracking ? "STATUS: ACTIVE" : "STATUS: IDLE"))
                            .font(.system(.headline, design: .monospaced))
                        
                        if manager.isTracking {
                            Text("Session in progress...")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Control Buttons
            HStack(spacing: 16) {
                if !manager.isTracking {
                    Button(action: { manager.start() }) {
                        Text("Start Work")
                            .frame(width: 140, height: 24)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    if manager.isPaused {
                        Button(action: { manager.resume() }) {
                            Label("Continue", systemImage: "play.fill")
                                .frame(width: 100, height: 24)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    } else {
                        Button(action: { manager.pause() }) {
                            Label("Pause", systemImage: "pause.fill")
                                .frame(width: 100, height: 24)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Button(action: { manager.stop() }) {
                        Label("End Work", systemImage: "stop.fill")
                            .frame(width: 100, height: 24)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - 2. ABOUT & HELP SECTION (The Documentation Table)
    private var aboutSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Branding Header
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        Text("FocusReport")
                            .font(.title).bold()
                        Text("Version 1.0.0 (Build 2025)")
                            .font(.caption).foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 10)
                
                Divider()
                
                // Documentation Content
                Group {
                    Text("Official Documentation").font(.headline)
                    
                    docRow(step: "START", desc: "Launch this app and click 'Start Work' at the beginning of your week/shift.")
                    docRow(step: "PAUSE", desc: "Click 'Pause' when taking a break. Click 'Continue' when returning.")
                    docRow(step: "STOP", desc: "Click 'End Work' when finished. This generates your mandatory PDF report.")
                    docRow(step: "REPORT", desc: "Send the generated PDF to your manager.")
                }
                
                // Mandatory Notice Box
                VStack(alignment: .leading, spacing: 10) {
                    Text("COMPLIANCE NOTICE")
                        .font(.caption).bold()
                        .foregroundColor(.red)
                    
                    Text("This software is property of XUN Innovation. Everyday reporting is mandatory to ensure accurate payroll processing.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                
                Text("© 2025 XUN Innovation. All rights reserved.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    // Helper for Documentation Rows
    private func docRow(step: String, desc: String) -> some View {
        HStack(alignment: .top) {
            Text(step)
                .font(.system(size: 10, weight: .bold))
                .padding(4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
                .frame(width: 50)
            
            Text(desc)
                .font(.subheadline)
        }
    }
}
