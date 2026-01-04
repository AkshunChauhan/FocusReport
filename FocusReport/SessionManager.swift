import AppKit
import Foundation
import Combine
import CoreAudio

class SessionManager: ObservableObject {
    @Published var isTracking = false
    @Published var isPaused = false
    @Published var currentSession: SessionData?
    
    private var timer: AnyCancellable?
    private let pollingInterval: TimeInterval = 10.0
    private let idleThreshold: TimeInterval = 60.0
    
    // Tracking Variables
    private var keystrokeCounter: Int = 0
    private var uniqueKeysPressed = Set<UInt16>()
    private var eventMonitor: Any?
    private var windowSwitchCounter: Int = 0
    private var mouseOnlyIntervals: Int = 0 // Track consecutive mouse-only (no key) intervals

    func start() {
        currentSession = SessionData(startTime: Date())
        isTracking = true
        isPaused = false
        setupMonitors()
        startTimer()
    }
    
    func pause() {
        isPaused = true
        currentSession?.addEvent(.pause)
        stopMonitoring()
        timer?.cancel()
    }
    
    func resume() {
        isPaused = false
        currentSession?.addEvent(.resume)
        setupMonitors()
        startTimer()
    }
    
    private func setupMonitors() {
        setupKeystrokeMonitor()
        
        // Monitor App Switches
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            self?.windowSwitchCounter += 1
        }
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
        stopMonitoring()
        isTracking = false
        isPaused = false
        
        if let session = currentSession {
            session.endTime = Date()
            session.addEvent(.stop)
            PDFGenerator.generate(for: session, password: "test123")
        }
        currentSession = nil
    }
    
    private func pulse() {
        guard let session = currentSession else { return }
        
        let anyEvent = CGEventType(rawValue: ~0)!
        let secondsSinceInput = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyEvent)
        
        let movedMouseRecently = secondsSinceInput < pollingInterval
        
        // --- Anti-Cheat Logic ---
        var flagReason: String? = nil
        
        // 1. Heavy Object Detection (Low Variance)
        if keystrokeCounter > 10 && uniqueKeysPressed.count < 3 {
            flagReason = "LOW_VARIANCE_INPUT"
        }
        
        // 2. Window Hopping Detection
        if windowSwitchCounter > 5 {
            flagReason = "EXCESSIVE_WINDOW_SWITCHING"
        }
        
        // 3. Low Engagement (Mouse only, no keys for > 30s)
        if keystrokeCounter == 0 && movedMouseRecently {
            mouseOnlyIntervals += 1
            if mouseOnlyIntervals >= 3 {
                flagReason = flagReason == nil ? "LOW_ENGAGEMENT (Mouse Only)" : flagReason! + ", LOW_ENGAGEMENT"
            }
        } else if keystrokeCounter > 0 {
            mouseOnlyIntervals = 0
        }
        
        let isHumanInput = (keystrokeCounter > 0 && flagReason == nil) || movedMouseRecently
        let isMediaPlaying = checkIfMediaIsPlaying()
        
        if secondsSinceInput >= idleThreshold {
            session.addIdleTime(pollingInterval)
            mouseOnlyIntervals = 0
        } else {
            if let activeApp = NSWorkspace.shared.frontmostApplication {
                let context = getAdvancedContext(for: activeApp)
                let appName = activeApp.localizedName ?? "Unknown App"
                
                let record = ActivityRecord(
                    appName: appName,
                    windowTitle: context.title,
                    folder: context.folder,
                    url: context.url,
                    keys: keystrokeCounter,
                    uniqueKeys: uniqueKeysPressed,
                    human: isHumanInput,
                    mediaPlaying: isMediaPlaying,
                    windowSwitches: windowSwitchCounter,
                    flagReason: flagReason
                )
                
                session.logActivity(appName: appName, seconds: pollingInterval, record: record)
                
                // Reset interval counters
                keystrokeCounter = 0
                uniqueKeysPressed.removeAll()
                windowSwitchCounter = 0
            }
        }
    }

    private func checkIfMediaIsPlaying() -> Bool {
        // 1. Check Music (com.apple.Music)
        if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty {
            if runAppleScript("tell application \"Music\" to get player state") == "playing" {
                return true
            }
        }
        
        // 2. Check Spotify (com.spotify.client)
        if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty {
            if runAppleScript("tell application \"Spotify\" to get player state") == "playing" {
                return true
            }
        }
        
        return isSystemAudioPlaying()
    }
    
    private func isSystemAudioPlaying() -> Bool {
        var defaultDevice = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultOutputDevice, mScope: kAudioObjectPropertyScopeGlobal, mElement: kAudioObjectPropertyElementMain)
        let result = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &defaultDevice)
        if result != noErr { return false }
        var isPlaying: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        address.mSelector = kAudioDevicePropertyDeviceIsRunningSomewhere
        let status = AudioObjectGetPropertyData(defaultDevice, &address, 0, nil, &size, &isPlaying)
        return status == noErr && isPlaying != 0
    }

    private func getAdvancedContext(for app: NSRunningApplication) -> (title: String?, folder: String?, url: String?) {
        let appName = app.localizedName ?? ""
        let title = getWindowTitleNative(for: app)
        var folder: String? = nil
        var url: String? = nil
        
        // 1. Browser Scrapers (Improved with 'is running' and 'windows count')
        if appName.contains("Google Chrome") {
            let chromeScript = "tell application \"Google Chrome\" to if running then if (count of windows) > 0 then return URL of active tab of front window"
            url = runAppleScript(chromeScript)
        } else if appName.contains("Safari") {
            let safariScript = "tell application \"Safari\" to if running then if (count of windows) > 0 then return URL of current tab of front window"
            url = runAppleScript(safariScript)
        }
        
        // 2. IDE / Project Scrapers
        // Note: Antigravity is likely the VS Code window title or workspace name
        if appName.contains("Visual Studio Code") || appName == "Code" || appName == "Antigravity" {
            let vsCodeScript = "tell application \"Visual Studio Code\" to if running then if (count of windows) > 0 then return path of active workspace folder"
            folder = runAppleScript(vsCodeScript)
            
            // If folder still nil, try getting the title of the front window which often contains the path
            if folder == nil { folder = title }
        } else if appName == "Xcode" {
            folder = runAppleScript("tell application \"Xcode\" to if running then if (count of windows) > 0 then return path of active workspace document")
        }
        
        return (title, folder, url)
    }

    private func getWindowTitleNative(for app: NSRunningApplication) -> String? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedWindow: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success {
            let windowElement = focusedWindow as! AXUIElement
            var title: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title) == .success {
                return title as? String
            }
        }
        // Fallback: Try kAXMainWindowAttribute
        var mainWindow: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXMainWindowAttribute as CFString, &mainWindow) == .success {
            let windowElement = mainWindow as! AXUIElement
            var title: AnyObject?
            if AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &title) == .success {
                return title as? String
            }
        }
        return nil
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        return NSAppleScript(source: source)?.executeAndReturnError(&error).stringValue
    }

    private func setupKeystrokeMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.keystrokeCounter += 1
            self?.uniqueKeysPressed.insert(event.keyCode)
        }
    }
    
    private func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
}
