import SwiftUI

struct ContentView: View {
    @StateObject private var manager = SessionManager()
    
    var body: some View {
        VStack(spacing: 25) {
            VStack(spacing: 5) {
                Text("FocusReport")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text("Manual Privacy Tracking")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if manager.isTracking {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Recording Activity...")
                        .font(.system(.body, design: .monospaced))
                }
            } else {
                Text("System Ready")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Button(action: {
                if manager.isTracking {
                    manager.stop()
                } else {
                    manager.start()
                }
            }) {
                Text(manager.isTracking ? "Stop & Save PDF" : "Start Session")
                    .fontWeight(.medium)
                    .frame(width: 180, height: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(manager.isTracking ? .red : .blue)
            
            if manager.isTracking {
                Text("Password will be: test123")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 320, height: 220)
        .padding()
    }
}
