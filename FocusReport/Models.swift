//
//  Models.swift
//  FocusReport
//
//  Created by Akshun Chauhan on 2025-12-19.
//

import Foundation

class SessionData {
    let startTime: Date
    var endTime: Date?
    var appUsage: [String: TimeInterval] = [:] // App Name : Seconds
    var totalIdleTime: TimeInterval = 0
    
    init(startTime: Date) {
        self.startTime = startTime
    }
    
    func logActivity(appName: String, seconds: TimeInterval) {
        appUsage[appName, default: 0] += seconds
    }
    
    func addIdleTime(_ seconds: TimeInterval) {
        totalIdleTime += seconds
    }
}
