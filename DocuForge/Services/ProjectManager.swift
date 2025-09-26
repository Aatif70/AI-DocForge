import Foundation

class ProjectManager {
    // Singleton instance
    static let shared = ProjectManager()
    
    private let fileManager = FileManager.default
    private let documentsDirectory: URL
    private let projectsDirectory: URL
    
    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        projectsDirectory = documentsDirectory.appendingPathComponent("DocuForge/Projects", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: projectsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating projects directory: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    // Save a project to disk
    func saveProject(_ project: Project) -> Bool {
        let projectURL = getProjectURL(project)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(project)
            try data.write(to: projectURL)
            return true
        } catch {
            print("Error saving project: \(error)")
            return false
        }
    }
    
    // Load all projects
    func loadProjects() -> [Project] {
        do {
            let projectFiles = try fileManager.contentsOfDirectory(at: projectsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = projectFiles.filter { $0.pathExtension == "json" }
            
            return try jsonFiles.compactMap { url in
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(Project.self, from: data)
            }
        } catch {
            print("Error loading projects: \(error)")
            return []
        }
    }
    
    // Delete a project
    func deleteProject(_ project: Project) {
        let projectURL = getProjectURL(project)
        
        do {
            try fileManager.removeItem(at: projectURL)
            
            // Also delete any associated PDF files
            for document in project.documents {
                if let pdfPath = document.pdfPath {
                    let pdfURL = URL(fileURLWithPath: pdfPath)
                    if fileManager.fileExists(atPath: pdfPath) {
                        try fileManager.removeItem(at: pdfURL)
                    }
                }
            }
        } catch {
            print("Error deleting project: \(error)")
        }
    }
    
    // Update or add a document to a project
    func updateProjectDocument(projectID: UUID, documentType: DocumentType, content: String, pdfPath: String) -> Project? {
        guard var project = getProject(with: projectID) else {
            print("ProjectManager: Failed to find project with ID \(projectID)")
            return nil
        }
        
        // Parse document content for metadata
        let wordCount = countWords(in: content)
        let readingTime = calculateReadingTime(wordCount: wordCount)
        let keyPoints = extractKeyPoints(from: content)
        
        // Check if document already exists
        if let index = project.documents.firstIndex(where: { $0.type == documentType }) {
            // Update existing document
            project.documents[index].content = content
            project.documents[index].pdfPath = pdfPath
            project.documents[index].lastModified = Date()
            project.documents[index].wordCount = wordCount
            project.documents[index].readingTime = readingTime
            project.documents[index].keyPoints = keyPoints
        } else {
            // Add new document
            let document = Document(
                id: UUID(),
                type: documentType,
                content: content,
                pdfPath: pdfPath,
                createdAt: Date(),
                lastModified: Date(),
                wordCount: wordCount,
                readingTime: readingTime,
                keyPoints: keyPoints
            )
            project.documents.append(document)
        }
        
        // Update project in database
        if saveProject(project) {
            print("ProjectManager: Successfully updated document \(documentType.rawValue) for project \(project.name)")
            return project
        } else {
            print("ProjectManager: Failed to save project after updating document")
            return nil
        }
    }
    
    // Get a project by ID
    func getProject(with id: UUID) -> Project? {
        return loadProjects().first { $0.id == id }
    }
    
    // MARK: - Private Methods
    
    private func getProjectURL(_ project: Project) -> URL {
        return projectsDirectory.appendingPathComponent("\(project.id.uuidString).json")
    }
    
    // Helper function to extract key points from document content
    private func extractKeyPoints(from content: String) -> [String] {
        var keyPoints: [String] = []
        
        // Split content into lines
        let lines = content.components(separatedBy: .newlines)
        
        // Look for bullet points or numbered items that might represent key points
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for bullet points or numbered items
            if (trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") || 
                trimmedLine.hasPrefix("• ") || 
                trimmedLine.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil) && 
                trimmedLine.count > 5 && trimmedLine.count < 120 {
                
                // Extract the content after the bullet/number
                var point = trimmedLine
                if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") || trimmedLine.hasPrefix("• ") {
                    point = String(trimmedLine.dropFirst(2))
                } else if let range = trimmedLine.range(of: "^\\d+\\.\\s", options: .regularExpression) {
                    point = String(trimmedLine[range.upperBound...])
                }
                
                // Add to key points if it's not too short
                point = point.trimmingCharacters(in: .whitespacesAndNewlines)
                if point.count > 10 && !point.isEmpty {
                    keyPoints.append(point)
                }
            }
            
            // Limit to 5 key points
            if keyPoints.count >= 5 {
                break
            }
        }
        
        return keyPoints
    }
    
    // Helper function to count words
    private func countWords(in text: String) -> Int {
        // Use natural language processing to get accurate word count
        let components = text.components(separatedBy: .whitespacesAndNewlines)
        let words = components.filter { !$0.isEmpty }
        return words.count
    }
    
    // Helper function to calculate reading time in minutes
    private func calculateReadingTime(wordCount: Int) -> Int {
        // Average reading speed is about 200-250 words per minute
        // Using 220 as a middle ground
        let readingSpeed = 220
        let minutes = Int(ceil(Double(wordCount) / Double(readingSpeed)))
        return max(1, minutes) // Minimum 1 minute
    }
} 