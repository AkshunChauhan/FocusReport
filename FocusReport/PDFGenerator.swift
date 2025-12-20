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
        
        // Ensure AppKit drawing (String.draw) targets the PDF context
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        
        let margin: CGFloat = 50
        var currentY: CGFloat = pageRect.height - margin
        
        func drawText(_ text: String, size: CGFloat, isBold: Bool = false) {
            let font = isBold ? NSFont.boldSystemFont(ofSize: size) : NSFont.systemFont(ofSize: size)
            let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.black]
            text.draw(at: CGPoint(x: margin, y: currentY), withAttributes: attrs)
            currentY -= (size + 12)
        }
        
        // --- Header ---
        drawText("FOCUSREPORT: SESSION LOG", size: 22, isBold: true)
        currentY -= 10
        
        // --- Session Details with Fixed Formatting ---
        let startStr = session.startTime.formatted(.dateTime.month(.abbreviated).day().year().hour().minute().second())
        let endStr = session.endTime?.formatted(.dateTime.month(.abbreviated).day().year().hour().minute().second()) ?? "Unknown"
        
        let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        let durationStr = formatter.string(from: duration) ?? "0s"
        
        drawText("Started: \(startStr)", size: 12)
        drawText("Stopped: \(endStr)", size: 12)
        drawText("Total Duration: \(durationStr)", size: 12, isBold: true)
        drawText("Total Idle Time: \(Int(session.totalIdleTime)) seconds", size: 12)
        
        currentY -= 20
        drawText("APPLICATION USAGE BREAKDOWN", size: 14, isBold: true)
        currentY -= 5
        
        // --- Breakdown ---
        if session.appUsage.isEmpty {
            drawText("No significant activity recorded.", size: 11)
        } else {
            // Sort apps by most time used
            let sortedApps = session.appUsage.sorted { $0.value > $1.value }
            for (appName, time) in sortedApps {
                let mins = Int(time) / 60
                let secs = Int(time) % 60
                drawText("• \(appName): \(mins)m \(secs)s", size: 11)
                if currentY < 50 { break }
            }
        }
        
        context.endPDFPage()
        context.closePDF()
        
        // --- Save and Encrypt ---
        let pdfDocument = PDFDocument(data: pdfData as Data)
        let options: [PDFDocumentWriteOption: Any] = [
            .userPasswordOption: password,
            .ownerPasswordOption: password
        ]
        
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folderURL = appSupport.appendingPathComponent("FocusReport")
        
        try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let fileURL = folderURL.appendingPathComponent("Report_\(Int(Date().timeIntervalSince1970)).pdf")
        
        pdfDocument?.write(to: fileURL, withOptions: options)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }
}
