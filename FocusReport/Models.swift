//
//  Models.swift
//  FocusReport
//
//  Created by Akshun Chauhan.
//  Copyright © 2026 Akshun Chauhan. All rights reserved.
//  Unauthorized resale or redistribution is strictly prohibited.
//

import Foundation

// This is the core "Forensic" data point
struct ActivityRecord: Codable {
    let timestamp: Date
    let appName: String
    var windowTitle: String? // Captured for deep context
    var projectFolderPath: String?
    var activeURL: String?
    var keystrokeCount: Int
    var uniqueKeysPressed: Set<UInt16> // To detect "heavy object" (low variance)
    var isHuman: Bool
    var mediaPlaying: Bool // Detect if music/video is active
    var windowSwitches: Int // Count of app switches in this interval
    var flagReason: String? // Why it was flagged as BOT?
    
    init(appName: String, windowTitle: String?, folder: String?, url: String?, keys: Int, uniqueKeys: Set<UInt16>, human: Bool, mediaPlaying: Bool, windowSwitches: Int, flagReason: String? = nil) {
        self.timestamp = Date()
        self.appName = appName
        self.windowTitle = windowTitle
        self.projectFolderPath = folder
        self.activeURL = url
        self.keystrokeCount = keys
        self.uniqueKeysPressed = uniqueKeys
        self.isHuman = human
        self.mediaPlaying = mediaPlaying
        self.windowSwitches = windowSwitches
        self.flagReason = flagReason
    }
}

enum SessionEventType: String, Codable {
    case start = "SESSION_START"
    case pause = "SESSION_PAUSE"
    case resume = "SESSION_RESUME"
    case stop = "SESSION_STOP"
}

struct SessionEvent: Codable {
    let timestamp: Date
    let type: SessionEventType
}

class SessionData {
    let startTime: Date
    var endTime: Date?
    var appUsage: [String: TimeInterval] = [:]
    var totalIdleTime: TimeInterval = 0
    var events: [SessionEvent] = []
    
    // This holds the minute-by-minute evidence for the PDF
    var detailedLog: [ActivityRecord] = []
    
    init(startTime: Date) {
        self.startTime = startTime
        self.addEvent(.start)
    }
    
    func addEvent(_ type: SessionEventType) {
        events.append(SessionEvent(timestamp: Date(), type: type))
    }
    
    func logActivity(appName: String, seconds: TimeInterval, record: ActivityRecord) {
        appUsage[appName, default: 0] += seconds
        detailedLog.append(record)
    }
    
    func addIdleTime(_ seconds: TimeInterval) {
        totalIdleTime += seconds
    }
}
