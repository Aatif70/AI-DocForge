import Foundation
import PDFKit
import SwiftUI

class PDFGenerator {
    // Generate a PDF from a markdown-formatted string
    func generatePDF(from content: String, fileName: String) -> URL? {
        // Create PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "DocuForge",
            kCGPDFContextAuthor: "DocuForge App",
            kCGPDFContextTitle: fileName
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Create PDF renderer
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        // Create directory for PDF using the app's documents directory
        // This guarantees that the file will be both saved persistently and shareable
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let docuforgeDirectory = documentsDirectory.appendingPathComponent("DocuForge", isDirectory: true)
        
        do {
            try FileManager.default.createDirectory(at: docuforgeDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Generate safe file name with timestamp to avoid conflicts
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            
            let safeFileName = fileName.replacingOccurrences(of: " ", with: "_")
                                      .replacingOccurrences(of: "/", with: "-")
                                      .replacingOccurrences(of: ":", with: "-")
                                      .replacingOccurrences(of: "\\", with: "-")
            let fileURL = docuforgeDirectory.appendingPathComponent("\(safeFileName)_\(timestamp).pdf")
            
            print("Saving PDF to: \(fileURL.path)")
            
            // Draw PDF content
            try renderer.writePDF(to: fileURL) { context in
                // First page
                context.beginPage()
                
                // Set up drawing parameters
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .natural
                paragraphStyle.lineBreakMode = .byWordWrapping
                
                let titleAttributes = [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24),
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
                
                let headingAttributes = [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
                
                let subheadingAttributes = [
                    NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14),
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
                
                let textAttributes = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12),
                    NSAttributedString.Key.paragraphStyle: paragraphStyle
                ]
                
                // Draw the text
                let contentLines = content.split(separator: "\n")
                var yPosition: CGFloat = 50
                
                for line in contentLines {
                    let lineString = String(line)
                    var attributes = textAttributes
                    var height: CGFloat = 20
                    
                    // Apply different formatting based on markdown style
                    if lineString.hasPrefix("# ") {
                        // Main title
                        let text = lineString.replacingOccurrences(of: "# ", with: "")
                        attributes = titleAttributes
                        height = 35
                        
                        // Draw a line under the title
                        context.cgContext.setStrokeColor(UIColor.gray.cgColor)
                        context.cgContext.setLineWidth(1.0)
                        context.cgContext.move(to: CGPoint(x: 50, y: yPosition + 30))
                        context.cgContext.addLine(to: CGPoint(x: pageWidth - 50, y: yPosition + 30))
                        context.cgContext.strokePath()
                        
                        yPosition += 10 // Add some padding after the line
                        
                        // Draw the title
                        text.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                    } else if lineString.hasPrefix("## ") {
                        // Section heading
                        let text = lineString.replacingOccurrences(of: "## ", with: "")
                        attributes = headingAttributes
                        height = 30
                        
                        // Add space before new section
                        yPosition += 10
                        text.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                    } else if lineString.hasPrefix("### ") {
                        // Subheading
                        let text = lineString.replacingOccurrences(of: "### ", with: "")
                        attributes = subheadingAttributes
                        height = 25
                        text.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                    } else if lineString.hasPrefix("- ") {
                        // Bullet point
                        let text = lineString
                        text.draw(at: CGPoint(x: 60, y: yPosition), withAttributes: attributes)
                    } else if lineString.hasPrefix("  ") {
                        // Indented text
                        let text = lineString
                        text.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: attributes)
                    } else if lineString.hasPrefix("---") {
                        // Horizontal line
                        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                        context.cgContext.setLineWidth(0.5)
                        context.cgContext.move(to: CGPoint(x: 50, y: yPosition + 10))
                        context.cgContext.addLine(to: CGPoint(x: pageWidth - 50, y: yPosition + 10))
                        context.cgContext.strokePath()
                    } else {
                        // Regular text
                        lineString.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: attributes)
                    }
                    
                    // Start a new page if we're getting close to the bottom
                    yPosition += height
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = 50
                    }
                }
            }
            
            return fileURL
        } catch {
            print("Error generating PDF: \(error)")
            return nil
        }
    }
} 