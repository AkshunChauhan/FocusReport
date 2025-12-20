import AppKit
import Foundation
import Combine

class SessionManager: ObservableObject {
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var currentSession: SessionData?
    
    private var timer: AnyCancellable?
    private let pollingInterval: TimeInterval = 5.0
    private let idleThreshold: TimeInterval = 60.0
    
    func start() {
        currentSession = SessionData(startTime: Date())
        isTracking = true
        isPaused = false
        startTimer()
    }
    
    func pause() {
        isPaused = true
        timer?.cancel()
    }
    
    func resume() {
        isPaused = false
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: pollingInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pulse()
            }
    }
    
    func stop() {
        timer?.cancel()
        isTracking = false
        isPaused = false
        
        if let session = currentSession {
            session.endTime = Date()
            PDFGenerator.generate(for: session, password: "test123")
        }
        currentSession = nil
    }
    
    private func pulse() {
        guard let session = currentSession else { return }
        let anyEvent = CGEventType(rawValue: ~0)!
        let secondsSinceInput = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
        
        if secondsSinceInput >= idleThreshold {
            session.addIdleTime(pollingInterval)
        } else {
            if let activeApp = NSWorkspace.shared.frontmostApplication?.localizedName {
                session.logActivity(appName: activeApp, seconds: pollingInterval)
            }
        }
    }
}
