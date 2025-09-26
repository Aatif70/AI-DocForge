import Foundation

struct Project: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var goal: String
    var targetAudience: String
    var coreFeatures: [String]
    var techStack: [String]
    var launchDate: Date
    var clientNotes: String
    var createdAt: Date = Date()
    var documents: [Document] = []
    
    // For document generation
    var formattedLaunchDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: launchDate)
    }
}

// Document types that can be generated
enum DocumentType: String, Codable, CaseIterable {
    case projectSummary = "Project Summary"
    case technicalRequirements = "Technical Requirements"
    case functionalSpecs = "Functional Specifications"
    case timeline = "Milestones & Timeline"
    case nda = "NDA Template"
}

// Represents a generated document
struct Document: Identifiable, Codable {
    var id: UUID
    var type: DocumentType
    var content: String
    var createdAt: Date
    var lastModified: Date
    var pdfPath: String? // Local path to saved PDF
    
    // Document metadata for enhanced search and categorization
    var wordCount: Int
    var readingTime: Int
    var keyPoints: [String]
    
    // Initialize with all metadata
    init(id: UUID = UUID(),
         type: DocumentType,
         content: String, 
         pdfPath: String?,
         createdAt: Date = Date(),
         lastModified: Date = Date(),
         wordCount: Int = 0,
         readingTime: Int = 1,
         keyPoints: [String] = []) {
        
        self.id = id
        self.type = type
        self.content = content
        self.pdfPath = pdfPath
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.wordCount = wordCount
        self.readingTime = readingTime
        self.keyPoints = keyPoints
    }
    
    // Legacy initializer for backward compatibility
    init(type: DocumentType, content: String, pdfPath: String?) {
        self.id = UUID()
        self.type = type
        self.content = content
        self.pdfPath = pdfPath
        self.createdAt = Date()
        self.lastModified = Date()
        
        // Calculate metadata
        self.wordCount = content.split(separator: " ").count
        self.readingTime = max(1, self.wordCount / 200)
        
        // Extract key points from headings
        self.keyPoints = content.split(separator: "\n")
            .filter { $0.hasPrefix("## ") }
            .prefix(5)
            .map { String($0.dropFirst(3)) }
    }
}