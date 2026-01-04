//
//  ContentView.swift
//  FocusReport
//
//  Created by Akshun Chauhan.
//  Copyright © 2026 Akshun Chauhan. All rights reserved.
//  Unauthorized resale or redistribution is strictly prohibited.
//

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
        VStack(spacing: 20) {
            // Permission Warnings
            if !manager.isAccessibilityGranted || !manager.isAutomationGranted {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("System Permissions Required")
                            .font(.headline)
                        Spacer()
                        Button("Fix Permissions") {
                            manager.checkPermissions()
                            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                            AXIsProcessTrustedWithOptions(options as CFDictionary)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    
                    if !manager.isAutomationGranted {
                        Text("Please allow 'Automation' for Chrome/Safari in System Settings > Privacy & Security.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

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
            VStack(alignment: .leading, spacing: 4) {
                Text("Version: 2.1.0 (Stable)")
                Text("Last Sync: \(Date().formatted())")
            }
            .font(.subheadline)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Developer Information")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                    Text("Built by **Akshun Chauhan**")
                }
                
                Text("© 2026 All Rights Reserved. FocusReport is a proprietary tool developed for high-fidelity auditing.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 5)
            
            Spacer()
        }
        .padding()
    }
    
}
