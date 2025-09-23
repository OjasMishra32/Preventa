import SwiftUI
import PDFKit

enum ReportExporter {
    /// Saves a simple text or markdown report to the temp directory.
    /// You can later upgrade this to proper PDF rendering.
    static func export(markdown: String) -> URL? {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("Preventa-Report.txt")

        do {
            try markdown.data(using: .utf8)?.write(to: tmp)
            return tmp
        } catch {
            print("Export failed: \(error.localizedDescription)")
            return nil
        }
    }
}
