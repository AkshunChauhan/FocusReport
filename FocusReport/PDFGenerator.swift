import Foundation
import PDFKit
import AppKit

struct PDFGenerator {
    static func generate(for session: SessionData, password: String) {
        let pdfData = NSMutableData()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        guard let consumer = CGDataConsumer(data: pdfData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else { return }
        
        context.beginPDFPage(nil)
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        
        let margin: CGFloat = 40
        var currentY: CGFloat = pageRect.height - margin
        
        func checkPageBreak(requiredHeight: CGFloat = 20) {
            if currentY < 50 + requiredHeight {
                context.endPDFPage()
                context.beginPDFPage(nil)
                NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
                currentY = pageRect.height - margin
            }
        }

        func drawText(_ text: String, size: CGFloat, x: CGFloat = 40, isBold: Bool = false, color: NSColor = .black) {
            let font = isBold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
            checkPageBreak(requiredHeight: size)
            text.draw(at: CGPoint(x: x, y: currentY), withAttributes: attrs)
            currentY -= (size + 6)
        }

        // --- Header ---
        drawText("FOCUSREPORT: COMMERCIAL FORENSIC AUDIT", size: 16, isBold: true)
        currentY -= 5
        
        let startStr = session.startTime.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        drawText("Audit Target: FocusReport System | Generated: \(Date().formatted())", size: 8, color: .gray)
        drawText("Session Start: \(startStr) | Total Duration: \(Int(duration/60)) mins", size: 9, isBold: true)
        currentY -= 15

        // --- Section 1: Session Timeline ---
        drawText("1. SESSION EVENT TIMELINE", size: 12, isBold: true)
        for event in session.events {
            let time = event.timestamp.formatted(.dateTime.hour().minute().second())
            drawText("• [\(time)] \(event.type.rawValue)", size: 9, color: event.type == .start ? .systemGreen : (event.type == .stop ? .systemRed : .gray))
        }
        currentY -= 15

        // --- Section 2: Application Summary ---
        drawText("2. RESOURCE USAGE BREAKDOWN", size: 12, isBold: true)
        let sortedApps = session.appUsage.sorted { $0.value > $1.value }
        for (appName, time) in sortedApps {
            let mins = Int(time) / 60
            drawText("• \(appName): \(mins)m \(Int(time) % 60)s", size: 9)
        }
        currentY -= 15
        
        // --- Section 3: Detailed Activity Log ---
        drawText("3. FORENSIC ACTIVITY TIMELINE (PROOF OF WORK)", size: 12, isBold: true)
        currentY -= 5
        
        // Table Headers
        let headers = ["Time", "App / Window / Context", "Keys", "Status"]
        let xOffsets: [CGFloat] = [40, 85, 490, 535]
        
        for (index, header) in headers.enumerated() {
            let attrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 8)]
            header.draw(at: CGPoint(x: xOffsets[index], y: currentY), withAttributes: attrs)
        }
        currentY -= 10
        context.setStrokeColor(NSColor.lightGray.cgColor)
        context.move(to: CGPoint(x: 40, y: currentY + 8))
        context.addLine(to: CGPoint(x: 570, y: currentY + 8))
        context.strokePath()

        // --- Data Rows (Grouped for Efficiency) ---
        var groupedLogs: [(record: ActivityRecord, duration: TimeInterval, totalKeys: Int)] = []
        
        for record in session.detailedLog {
            if let lastIndex = groupedLogs.indices.last {
                let last = groupedLogs[lastIndex]
                
                // Group if app is same AND titles match AND media state is same AND flags match
                let titlesMatch = last.record.windowTitle == record.windowTitle
                let canSeedMetadata = last.record.windowTitle == nil && record.windowTitle != nil
                let mediaMatch = last.record.mediaPlaying == record.mediaPlaying
                let flagsMatch = last.record.flagReason == record.flagReason
                
                if last.record.appName == record.appName && 
                   flagsMatch &&
                   mediaMatch &&
                   (titlesMatch || canSeedMetadata) {
                    
                    let updatedRecord = canSeedMetadata ? record : last.record
                    let updatedDuration = last.duration + 10.0
                    let updatedKeys = last.totalKeys + record.keystrokeCount
                    groupedLogs[lastIndex] = (updatedRecord, updatedDuration, updatedKeys)
                } else {
                    groupedLogs.append((record, 10.0, record.keystrokeCount))
                }
            } else {
                groupedLogs.append((record, 10.0, record.keystrokeCount))
            }
        }

        for (record, duration, totalKeys) in groupedLogs {
            checkPageBreak(requiredHeight: 35)
            
            let timeStr = record.timestamp.formatted(.dateTime.hour(.twoDigits(amPM: .abbreviated)).minute(.twoDigits))
            
            // Draw Time & Duration
            let timeAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 7)]
            let durationStr = duration >= 60 ? "\(Int(duration/60))m" : "\(Int(duration))s"
            "\(timeStr) (\(durationStr))".draw(at: CGPoint(x: xOffsets[0], y: currentY), withAttributes: timeAttrs)
            
            // Draw App & Context
            let appAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 8)]
            record.appName.draw(at: CGPoint(x: xOffsets[1], y: currentY), withAttributes: appAttrs)
            
            let contextY = currentY - 10
            let contextText = record.windowTitle ?? record.projectFolderPath ?? record.activeURL ?? "No metadata captured"
            let subAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 7), .foregroundColor: NSColor.darkGray]
            
            let displayContext = contextText.count > 110 ? String(contextText.prefix(107)) + "..." : contextText
            displayContext.draw(at: CGPoint(x: xOffsets[1], y: contextY), withAttributes: subAttrs)
            
            // Metrics
            let metricAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 8)]
            "\(totalKeys)".draw(at: CGPoint(x: xOffsets[2], y: currentY), withAttributes: metricAttrs)
            
            // Status/Anti-Cheat + MEDIA flag
            var statusText = record.flagReason != nil ? "FLAGGED" : (record.isHuman ? "HUMAN" : "IDLE")
            if record.mediaPlaying { statusText += " + MEDIA" }
            
            let statusColor = record.flagReason != nil ? NSColor.systemRed : (record.isHuman ? NSColor.systemGreen : NSColor.systemGray)
            let statusAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.boldSystemFont(ofSize: 7), .foregroundColor: statusColor]
            statusText.draw(at: CGPoint(x: xOffsets[3], y: currentY), withAttributes: statusAttrs)
            
            if let reason = record.flagReason {
                let reasonAttrs: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 6), .foregroundColor: NSColor.systemRed]
                reason.draw(at: CGPoint(x: xOffsets[3], y: contextY), withAttributes: reasonAttrs)
            }
            
            currentY -= 28
        }

        context.endPDFPage()
        context.closePDF()
        saveAndEncrypt(pdfData: pdfData, password: password)
    }
    
    private static func saveAndEncrypt(pdfData: NSMutableData, password: String) {
        let pdfDocument = PDFDocument(data: pdfData as Data)
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ]
        
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folderURL = appSupport.appendingPathComponent("FocusReport")
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        
        let fileURL = folderURL.appendingPathComponent("Forensic_Report_\(Int(Date().timeIntervalSince1970)).pdf")
        pdfDocument?.write(to: fileURL, withOptions: options)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
}
