import Foundation
import NaturalLanguage

class DocumentGenerator {
    enum GenerationMode {
        case offline
        case openAI
    }
    
    // Singleton instance
    static let shared = DocumentGenerator()
    
    private var generationMode: GenerationMode = .openAI
    
    private init() {
        // Default to OpenAI mode if configured
        if OpenAIService.shared.isConfigured {
            self.generationMode = .openAI
        } else {
            self.generationMode = .offline
            print("DocumentGenerator: OpenAI not configured, using offline mode")
        }
    }
    
    // Set generation mode
    func setGenerationMode(_ mode: GenerationMode) {
        self.generationMode = mode
        print("DocumentGenerator: Mode set to \(mode == .openAI ? "OpenAI" : "Offline")")
    }
    
    // Get current generation mode
    func getGenerationMode() -> GenerationMode {
        return generationMode
    }
    
    // Check if OpenAI can be used
    func canUseOpenAI() -> Bool {
        return OpenAIService.shared.isConfigured
    }
    
    // Generate document content based on project information and document type
    func generateDocument(for project: Project, type: DocumentType, completion: @escaping (String) -> Void) {
        print("DocumentGenerator: Using \(generationMode == .openAI ? "OpenAI" : "Offline") mode")
        print("DocumentGenerator: OpenAI configured: \(canUseOpenAI())")
        
        // Check if OpenAI is available
        if canUseOpenAI() {
            // Use OpenAI for generation
            OpenAIService.shared.generateDocument(for: project, type: type) { result in
                switch result {
                case .success(let content):
                    print("DocumentGenerator: Successfully generated content with OpenAI")
                    completion(content)
                case .failure(let error):
                    print("OpenAI Error: \(error.localizedDescription)")
                    // Fallback to a simple template
                    let fallbackContent = self.generateFallbackDocument(for: project, type: type)
                    completion(fallbackContent)
                }
            }
        } else {
            // Use simple fallback template if OpenAI isn't configured
            let fallbackContent = self.generateFallbackDocument(for: project, type: type)
            completion(fallbackContent)
        }
    }
    
    // Synchronous version for immediate use
    func generateDocument(for project: Project, type: DocumentType) -> String {
        // Just generate a simple placeholder that directs user to configure OpenAI
        return generateFallbackDocument(for: project, type: type)
    }
    
    // Very simple fallback template when OpenAI is unavailable
    private func generateFallbackDocument(for project: Project, type: DocumentType) -> String {
        let docTypeStr = type.rawValue
        
        return """
        # \(project.name.uppercased()) - \(docTypeStr.uppercased())
        
        ## OpenAI Not Available
        
        This is a simplified fallback document as OpenAI is currently unavailable. To generate comprehensive documents:
        
        1. Go to Settings
        2. Add your OpenAI API key
        3. Enable the "Use OpenAI" toggle
        4. Return to this page and regenerate the document
        
        ## Project Details
        
        **Name:** \(project.name)
        **Description:** \(project.description)
        **Goal:** \(project.goal)
        **Target Audience:** \(project.targetAudience)
        **Launch Date:** \(project.formattedLaunchDate)
        
        ## Core Features
        \(project.coreFeatures.map { "- \($0)" }.joined(separator: "\n"))
        
        ## Tech Stack
        \(project.techStack.map { "- \($0)" }.joined(separator: "\n"))
        
        ## Client Notes
        \(project.clientNotes)
        
        ---
        This fallback document was generated on \(formattedCurrentDate()) because OpenAI is not configured.
        """
    }
    
    // Helper function for date formatting
    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    
    // MARK: - Offline Document Generation Methods
    
    private func generateOfflineDocument(for project: Project, type: DocumentType) -> String {
        switch type {
        case .projectSummary:
            return generateProjectSummary(project)
        case .technicalRequirements:
            return generateTechnicalRequirements(project)
        case .functionalSpecs:
            return generateFunctionalSpecs(project)
        case .timeline:
            return generateTimeline(project)
        case .nda:
            return generateNDA(project)
        }
    }
    
    // MARK: - Private Document Generation Methods
    
    private func generateProjectSummary(_ project: Project) -> String {
        let keywords = extractKeywords(from: project.description + " " + project.goal)
        let (sentiment, confidence) = analyzeSentiment(of: project.description)
        
        // Generate project tone based on sentiment analysis
        let projectTone: String
        if sentiment > 0.3 {
            projectTone = "The project has a positive outlook with an emphasis on innovation and opportunity."
        } else if sentiment < -0.3 {
            projectTone = "The project addresses critical challenges and aims to solve important problems."
        } else {
            projectTone = "The project has a balanced approach focusing on practical implementation."
        }
        
        // Generate a summary expansion based on keywords and project details
        let keywordGroups = groupKeywordsByRelevance(keywords, for: project)
        let summaryExtension = generateSummaryExtension(from: keywordGroups, project: project)
        
        return """
        # \(project.name.uppercased()) - PROJECT SUMMARY
        
        ## Overview
        \(project.description)
        
        ## Extended Summary
        \(summaryExtension)
        
        ## Project Approach
        \(projectTone) This project targets \(project.targetAudience) with an anticipated completion by \(project.formattedLaunchDate).
        
        ## Project Goal
        \(project.goal)
        
        ## Target Audience
        \(project.targetAudience)
        
        ## Core Features
        \(project.coreFeatures.enumerated().map { index, feature in
            return "- \(feature)"
        }.joined(separator: "\n"))
        
        ## Technologies
        \(project.techStack.enumerated().map { index, tech in
            return "- \(tech)"
        }.joined(separator: "\n"))
        
        ## Launch Date
        \(project.formattedLaunchDate)
        
        ## Additional Notes
        \(project.clientNotes)
        
        ## Key Project Terms
        \(keywords.joined(separator: ", "))
        
        --- 
        Generated by DocuForge on \(formattedCurrentDate())
        """
    }
    
    private func generateTechnicalRequirements(_ project: Project) -> String {
        let complexity = calculateProjectComplexity(project)
        let techRecommendations = generateTechnologyRecommendations(project)
        let securityRecommendations = generateSecurityRecommendations(project)
        
        return """
        # \(project.name.uppercased()) - TECHNICAL REQUIREMENTS
        
        ## Overview
        This document outlines the technical specifications and requirements for \(project.name). Based on analysis, this is a \(complexity.description) complexity project requiring \(complexity.developmentEffort) of development effort.
        
        ## Project Stack
        \(project.techStack.enumerated().map { index, tech in
            return "- \(tech)"
        }.joined(separator: "\n"))
        
        ## System Architecture
        Based on the project requirements, the following architecture is recommended:
        
        ### Frontend
        \(techRecommendations.frontend)
        
        ### Backend
        \(techRecommendations.backend)
        
        ### Data Storage
        \(techRecommendations.storage)
        
        ### Authentication
        \(techRecommendations.authentication)
        
        ## Technical Dependencies
        The project will require the following technical dependencies:
        
        \(generateDependenciesRecommendation(from: project.techStack))
        
        ## Security Considerations
        \(securityRecommendations)
        
        ## Development Environment
        - Recommended IDE: Xcode for iOS/macOS development
        - Version control: Git with feature branch workflow
        - Dependency management: Swift Package Manager
        - Testing framework: XCTest for unit and UI testing
        
        ## Performance Requirements
        - UI responsiveness: < 100ms response time for user interactions
        - Document generation: < 3 seconds for PDF creation
        - Storage efficiency: Minimize document size for optimal local storage
        
        ## Development Timeline
        - Development Start: Immediate
        - Estimated Completion: \(project.formattedLaunchDate)
        - Recommended approach: \(complexity.recommendedApproach)
        
        ## Technical Considerations
        - Data Privacy: \(techRecommendations.privacy)
        - Performance: \(techRecommendations.performance)
        - Scalability: \(generateScalabilityRecommendation(from: project))
        - Offline Support: All features must function without internet connectivity
        
        --- 
        Generated by DocuForge on \(formattedCurrentDate())
        """
    }
    
    private func generateFunctionalSpecs(_ project: Project) -> String {
        return """
        # \(project.name.uppercased()) - FUNCTIONAL SPECIFICATIONS
        
        ## Overview
        This document outlines the functional specifications for \(project.name).
        
        ## Core Functionality
        \(project.coreFeatures.enumerated().map { index, feature in
            return "### Feature \(index + 1): \(feature)\n" +
                   "Description: \(generateFeatureDescription(feature))\n" +
                   "User Flow: \(generateUserFlow(feature))\n" +
                   "Success Criteria: \(generateSuccessCriteria(feature))\n"
        }.joined(separator: "\n\n"))
        
        ## User Roles and Permissions
        Based on the target audience (\(project.targetAudience)), the following user roles are defined:
        
        - Primary Users: \(project.targetAudience)
        - Admin Users: Project creators and editors
        
        ## Data Entities
        The following key data entities will be maintained:
        
        - Projects
        - Documents
        - User Preferences
        
        ## Cross-Functional Requirements
        - Usability: Intuitive, user-friendly interface
        - Performance: Responsive UI, fast document generation
        - Security: Local data storage only
        - Offline Capability: 100% functionality without internet connection
        
        --- 
        Generated by DocuForge on \(formattedCurrentDate())
        """
    }
    
    private func generateTimeline(_ project: Project) -> String {
        let now = Date()
        let calendar = Calendar.current
        let launchDateComponents = calendar.dateComponents([.day], from: now, to: project.launchDate)
        let totalDays = max(launchDateComponents.day ?? 30, 30)
        
        let phases = generateProjectPhases(totalDays: totalDays, features: project.coreFeatures)
        
        return """
        # \(project.name.uppercased()) - MILESTONES & TIMELINE
        
        ## Project Timeline Overview
        - Project Start: \(formattedDate(now))
        - Target Completion: \(project.formattedLaunchDate)
        - Total Duration: \(totalDays) days
        
        ## Key Milestones
        \(phases.enumerated().map { index, phase in
            return "### Phase \(index + 1): \(phase.name) (\(phase.duration) days)\n" +
                   "Start Date: \(formattedDate(phase.startDate))\n" +
                   "End Date: \(formattedDate(phase.endDate))\n" +
                   "Deliverables:\n" +
                   phase.deliverables.map { "- \($0)" }.joined(separator: "\n")
        }.joined(separator: "\n\n"))
        
        ## Risk Assessment
        - Timeline Risk: Medium
        - Technical Risk: Low
        - Resource Risk: Low
        
        ## Timeline Assumptions
        - Full-time resource allocation
        - No major scope changes
        - Regular progress reviews
        
        --- 
        Generated by DocuForge on \(formattedCurrentDate())
        """
    }
    
    private func generateNDA(_ project: Project) -> String {
        return """
        # NON-DISCLOSURE AGREEMENT
        
        ## CONFIDENTIALITY AGREEMENT
        
        This NON-DISCLOSURE AGREEMENT (the "Agreement") is made and entered into as of \(formattedCurrentDate()) (the "Effective Date") by and between the parties.
        
        ## PROJECT DETAILS
        
        Project Name: \(project.name)
        Project Description: \(project.description)
        
        ## CONFIDENTIALITY TERMS
        
        1. **Definition of Confidential Information**
           "Confidential Information" means any information disclosed by either party to the other party, either directly or indirectly, in writing, orally or by inspection of tangible objects, including without limitation documents, prototypes, samples, plant and equipment, research, product plans, products, services, customer lists, markets, software, developments, inventions, processes, formulas, technology, designs, drawings, engineering, hardware configuration, marketing or finance materials.
        
        2. **Non-Disclosure and Non-Use**
           Each party agrees not to disclose any Confidential Information of the other party to third parties or to employees, except to those employees who are required to have the information to evaluate or engage in discussions concerning the contemplated business relationship.
        
        3. **Term**
           The obligations under this Agreement shall remain in effect until the earlier of:
           - The Project Launch Date: \(project.formattedLaunchDate)
           - Written release from these obligations by both parties
        
        4. **Governing Law**
           This Agreement shall be governed by and construed in accordance with the laws of [INSERT JURISDICTION].
        
        ## SIGNATURES
        
        Party 1: _________________________ Date: _____________
        
        Party 2: _________________________ Date: _____________
        
        --- 
        Generated by DocuForge on \(formattedCurrentDate())
        """
    }
    
    // MARK: - Helper Methods
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func extractKeywords(from text: String) -> [String] {
        // Using NaturalLanguage for more advanced keyword extraction
        
        // Create an NLTagger for named entities, lemmatization, and parts of speech
        let tagger = NLTagger(tagSchemes: [.nameType, .lemma, .lexicalClass])
        tagger.string = text
        
        var namedEntities: [String] = []
        var nouns: [String] = []
        var verbs: [String] = []
        var adjectives: [String] = []
        
        // Common words to filter out (stopwords)
        let stopwords = Set(["the", "and", "this", "that", "with", "for", "will", "have", "from", "not", "are", "were", "was", "been", "being", "can", "could", "should", "would", "shall", "will", "may", "might", "must"])
        
        // Extract named entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag = tag {
                let word = String(text[tokenRange])
                
                // Add named entities
                if tag != .other {
                    namedEntities.append(word)
                }
            }
            return true
        }
        
        // Extract parts of speech
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let tag = tag {
                let word = String(text[tokenRange]).lowercased()
                
                // Skip common short words and stopwords
                if word.count <= 2 || stopwords.contains(word) {
                    return true
                }
                
                // Categorize by part of speech
                switch tag {
                case .noun:
                    nouns.append(word)
                case .verb:
                    verbs.append(word)
                case .adjective:
                    adjectives.append(word)
                default:
                    break
                }
            }
            return true
        }
        
        // Extract lemmas to consolidate different forms of the same word
        var lemmas = [String: Int]() // word: frequency
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lemma, options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            if let lemma = tag?.rawValue, !lemma.isEmpty {
                let word = lemma.lowercased()
                if word.count > 2 && !stopwords.contains(word) {
                    lemmas[word, default: 0] += 1
                }
            }
            return true
        }
        
        // Combine all extracted keywords, prioritizing named entities
        var allKeywords = namedEntities
        
        // Add top 5 nouns (by frequency, if duplicated in lemmas)
        let topNouns = nouns
            .filter { !allKeywords.contains($0) }
            .sorted { lemmas[$0, default: 0] > lemmas[$1, default: 0] }
            .prefix(5)
        allKeywords.append(contentsOf: topNouns)
        
        // Add top 3 verbs
        let topVerbs = verbs
            .filter { !allKeywords.contains($0) }
            .sorted { lemmas[$0, default: 0] > lemmas[$1, default: 0] }
            .prefix(3)
        allKeywords.append(contentsOf: topVerbs)
        
        // Add top 3 adjectives
        let topAdjectives = adjectives
            .filter { !allKeywords.contains($0) }
            .sorted { lemmas[$0, default: 0] > lemmas[$1, default: 0] }
            .prefix(3)
        allKeywords.append(contentsOf: topAdjectives)
        
        // Add any remaining high-frequency lemmas
        let topLemmas = lemmas.sorted { $0.value > $1.value }
            .map { $0.key }
            .filter { !allKeywords.contains($0) }
            .prefix(5)
        allKeywords.append(contentsOf: topLemmas)
        
        // Return unique keywords, limit to 15
        return Array(NSOrderedSet(array: allKeywords).array as! [String]).prefix(15).map { $0 }
    }
    
    // Add sentiment analysis for project description
    private func analyzeSentiment(of text: String) -> (sentiment: Float, confidence: Float) {
        guard !text.isEmpty else { return (0, 0) }
        
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = Float(sentiment?.rawValue ?? "0") ?? 0
        
        // Calculate confidence based on text length and content
        let confidence: Float = Float(min(text.count, 100)) / 100.0
        
        return (sentiment: score, confidence: confidence)
    }
    
    // MARK: - Document Generation Helper Methods
    
    private struct ProjectPhase {
        let name: String
        let duration: Int
        let startDate: Date
        let endDate: Date
        let deliverables: [String]
    }
    
    private func generateProjectPhases(totalDays: Int, features: [String]) -> [ProjectPhase] {
        let planningDuration = max(Int(Double(totalDays) * 0.2), 5) // 20% of time for planning
        let developmentDuration = max(Int(Double(totalDays) * 0.5), 10) // 50% of time for development
        let testingDuration = max(Int(Double(totalDays) * 0.2), 5) // 20% of time for testing
        let deploymentDuration = totalDays - planningDuration - developmentDuration - testingDuration // Remaining time for deployment
        
        let now = Date()
        let calendar = Calendar.current
        
        let planningStart = now
        let planningEnd = calendar.date(byAdding: .day, value: planningDuration, to: planningStart)!
        
        let developmentStart = planningEnd
        let developmentEnd = calendar.date(byAdding: .day, value: developmentDuration, to: developmentStart)!
        
        let testingStart = developmentEnd
        let testingEnd = calendar.date(byAdding: .day, value: testingDuration, to: testingStart)!
        
        let deploymentStart = testingEnd
        let deploymentEnd = calendar.date(byAdding: .day, value: deploymentDuration, to: deploymentStart)!
        
        // Divide features across development phases
        let featureCount = features.count
        let featuresPerPhase = max(featureCount / 3, 1)
        
        return [
            ProjectPhase(
                name: "Planning & Design",
                duration: planningDuration,
                startDate: planningStart,
                endDate: planningEnd,
                deliverables: [
                    "Project requirements document",
                    "UI/UX design mockups",
                    "Technical architecture document",
                    "Development roadmap"
                ]
            ),
            ProjectPhase(
                name: "Development - Core Features",
                duration: developmentDuration,
                startDate: developmentStart,
                endDate: developmentEnd,
                deliverables: features.prefix(featuresPerPhase).map { "Implementation of: \($0)" }
            ),
            ProjectPhase(
                name: "Testing & Refinement",
                duration: testingDuration,
                startDate: testingStart,
                endDate: testingEnd,
                deliverables: [
                    "Unit tests",
                    "Integration tests",
                    "User acceptance testing",
                    "Bug fixes and refinements"
                ]
            ),
            ProjectPhase(
                name: "Deployment & Launch",
                duration: deploymentDuration,
                startDate: deploymentStart,
                endDate: deploymentEnd,
                deliverables: [
                    "App store submission",
                    "Marketing materials",
                    "User documentation",
                    "Launch event coordination"
                ]
            )
        ]
    }
    
    private func generateFrontendRecommendation(from techStack: [String]) -> String {
        let frontend = techStack.filter { $0.lowercased().contains("ui") || $0.lowercased().contains("front") }
        return frontend.isEmpty ? "SwiftUI" : frontend.joined(separator: ", ")
    }
    
    private func generateBackendRecommendation(from techStack: [String]) -> String {
        let backend = techStack.filter { $0.lowercased().contains("kit") || $0.lowercased().contains("framework") }
        return backend.isEmpty ? "Swift + Core Frameworks" : backend.joined(separator: ", ")
    }
    
    private func generateDependenciesRecommendation(from techStack: [String]) -> String {
        var dependencies = [
            "- SwiftUI: UI framework",
            "- NaturalLanguage: For text processing and analysis",
            "- PDFKit: For document generation and export",
            "- FileManager: For local file storage"
        ]
        
        if techStack.contains(where: { $0.lowercased().contains("data") }) {
            dependencies.append("- CoreData: For structured data storage")
        }
        
        return dependencies.joined(separator: "\n")
    }
    
    private func generateScalabilityRecommendation(from project: Project) -> String {
        let complexity = project.coreFeatures.count + project.techStack.count
        
        if complexity > 10 {
            return "Design for high scalability with modular architecture"
        } else if complexity > 5 {
            return "Moderate scalability requirements expected"
        } else {
            return "Minimal scalability concerns for initial release"
        }
    }
    
    private func generateFeatureDescription(_ feature: String) -> String {
        // Extract key verbs and nouns from the feature
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = feature
        
        var verbs: [String] = []
        var nouns: [String] = []
        
        tagger.enumerateTags(in: feature.startIndex..<feature.endIndex, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag {
                let word = String(feature[tokenRange])
                switch tag {
                case .verb:
                    verbs.append(word.lowercased())
                case .noun:
                    nouns.append(word.lowercased())
                default:
                    break
                }
            }
            return true
        }
        
        // Generate a more descriptive feature explanation based on verbs and nouns
        if !verbs.isEmpty && !nouns.isEmpty {
            let verb = getEnhancedVerb(for: verbs.first ?? "use")
            let noun = nouns.first ?? "functionality"
            
            // Get related functionality based on the feature name
            let additionalContext = getContextForFeature(feature)
            
            return "This feature \(verb) \(noun) \(additionalContext). It enhances the user experience by providing seamless access to \(feature.lowercased()) functionality."
        } else {
            return "This feature enables users to work with \(feature.lowercased()) efficiently. It provides core functionality needed to complete this aspect of the project."
        }
    }
    
    private func getEnhancedVerb(for verb: String) -> String {
        // Map common verbs to more descriptive alternatives
        let verbEnhancements = [
            "use": "empowers users to utilize",
            "access": "provides streamlined access to",
            "view": "visualizes and presents",
            "create": "facilitates the creation of",
            "edit": "enables intuitive editing of",
            "delete": "manages the removal of",
            "save": "securely stores",
            "share": "simplifies sharing of",
            "upload": "handles seamless uploading of",
            "download": "efficiently retrieves",
            "search": "enables intelligent searching across",
            "filter": "provides powerful filtering of",
            "sort": "intelligently organizes",
            "manage": "streamlines the management of",
            "generate": "automates the generation of",
            "analyze": "performs in-depth analysis of",
            "track": "precisely monitors",
            "monitor": "continuously observes",
            "report": "generates comprehensive reports on",
            "integrate": "seamlessly connects with",
            "authenticate": "securely verifies"
        ]
        
        return verbEnhancements[verb.lowercased()] ?? "enables users to work with"
    }
    
    private func getContextForFeature(_ feature: String) -> String {
        // Provide contextual information based on feature keywords
        let featureLower = feature.lowercased()
        
        if featureLower.contains("user") || featureLower.contains("account") || featureLower.contains("profile") || featureLower.contains("auth") {
            return "with appropriate security and privacy controls"
        } else if featureLower.contains("data") || featureLower.contains("file") || featureLower.contains("document") || featureLower.contains("storage") {
            return "with local storage for offline availability"
        } else if featureLower.contains("report") || featureLower.contains("chart") || featureLower.contains("graph") || featureLower.contains("analytics") {
            return "with clear visual representations"
        } else if featureLower.contains("settings") || featureLower.contains("config") || featureLower.contains("preferences") {
            return "with user customization options"
        } else if featureLower.contains("export") || featureLower.contains("share") || featureLower.contains("send") {
            return "across standard device interfaces"
        } else if featureLower.contains("search") || featureLower.contains("find") || featureLower.contains("filter") {
            return "using optimized algorithms for fast results"
        } else {
            return "in an intuitive, user-friendly interface"
        }
    }
    
    private func generateUserFlow(_ feature: String) -> String {
        // Create more detailed user flows based on feature content
        let featureLower = feature.lowercased()
        
        // Default flow parts
        var initiationStep = "User navigates to the relevant section"
        var interactionStep = "interacts with the interface"
        var completionStep = "and completes the process efficiently"
        
        // Determine feature type and customize flow
        if featureLower.contains("create") || featureLower.contains("add") || featureLower.contains("new") {
            initiationStep = "User selects the 'Add New' or '+' button"
            interactionStep = "completes all required fields in the form"
            completionStep = "and saves to create a new entry"
        } else if featureLower.contains("edit") || featureLower.contains("update") || featureLower.contains("modify") {
            initiationStep = "User selects the existing item"
            interactionStep = "modifies the necessary information"
            completionStep = "and confirms changes to update"
        } else if featureLower.contains("delete") || featureLower.contains("remove") {
            initiationStep = "User selects the item to be removed"
            interactionStep = "confirms the deletion request"
            completionStep = "and the system removes the item with appropriate feedback"
        } else if featureLower.contains("search") || featureLower.contains("find") || featureLower.contains("filter") {
            initiationStep = "User accesses the search interface"
            interactionStep = "enters search criteria or filters"
            completionStep = "and reviews the dynamically updated results"
        } else if featureLower.contains("view") || featureLower.contains("display") || featureLower.contains("show") {
            initiationStep = "User navigates to the appropriate section"
            interactionStep = "selects viewing preferences if applicable"
            completionStep = "and examines the clearly presented information"
        } else if featureLower.contains("export") || featureLower.contains("share") || featureLower.contains("send") {
            initiationStep = "User selects content to be exported"
            interactionStep = "chooses the desired export format"
            completionStep = "and initiates the export to complete the process"
        } else if featureLower.contains("import") || featureLower.contains("upload") {
            initiationStep = "User initiates the import process"
            interactionStep = "selects the source file or data"
            completionStep = "and confirms to complete the import operation"
        } else if featureLower.contains("settings") || featureLower.contains("config") || featureLower.contains("preferences") {
            initiationStep = "User navigates to the settings screen"
            interactionStep = "adjusts the desired configuration options"
            completionStep = "and saves to apply the new preferences"
        }
        
        return "\(initiationStep), \(interactionStep), \(completionStep)."
    }
    
    private func generateSuccessCriteria(_ feature: String) -> String {
        // Generate specific success criteria based on the feature
        let featureLower = feature.lowercased()
        
        var functionalCriteria = "Feature functions without errors"
        var performanceCriteria = "with appropriate response time"
        var userCriteria = "and meets user needs effectively"
        
        // Customize criteria based on feature type
        if featureLower.contains("create") || featureLower.contains("add") || featureLower.contains("new") {
            functionalCriteria = "New items are created and stored correctly"
            performanceCriteria = "with proper validation of inputs"
            userCriteria = "and immediate feedback on success"
        } else if featureLower.contains("search") || featureLower.contains("find") || featureLower.contains("filter") {
            functionalCriteria = "Search results are accurate and relevant"
            performanceCriteria = "with response times under 1 second"
            userCriteria = "and intuitive presentation of results"
        } else if featureLower.contains("export") || featureLower.contains("pdf") || featureLower.contains("document") {
            functionalCriteria = "Documents are generated with correct formatting"
            performanceCriteria = "and include all required content"
            userCriteria = "while being easily readable and professional"
        } else if featureLower.contains("user") || featureLower.contains("account") || featureLower.contains("profile") {
            functionalCriteria = "User data is managed correctly and securely"
            performanceCriteria = "with appropriate privacy controls"
            userCriteria = "and intuitive profile management"
        } else if featureLower.contains("data") || featureLower.contains("storage") || featureLower.contains("save") {
            functionalCriteria = "Data is stored correctly and persistently"
            performanceCriteria = "with proper error handling for edge cases"
            userCriteria = "and appropriate confirmation of successful operations"
        } else if featureLower.contains("ui") || featureLower.contains("interface") || featureLower.contains("display") {
            functionalCriteria = "Interface elements render correctly across devices"
            performanceCriteria = "with smooth transitions and animations"
            userCriteria = "and clear visual hierarchy for usability"
        }
        
        return "\(functionalCriteria) \(performanceCriteria) \(userCriteria)."
    }
    
    // Helper methods for enhanced document generation
    private func groupKeywordsByRelevance(_ keywords: [String], for project: Project) -> [String: [String]] {
        var technical = [String]()
        var business = [String]()
        var audience = [String]()
        
        // Technical terms often include technology words
        let technicalIndicators = ["app", "software", "code", "data", "system", "platform", "api", "interface", "mobile", "web", "cloud", "server", "client", "database", "ui", "ux"]
        
        // Business terms often include these words
        let businessIndicators = ["market", "user", "customer", "revenue", "cost", "price", "value", "business", "industry", "product", "service", "solution", "strategy", "plan", "goal"]
        
        // Categorize each keyword
        for keyword in keywords {
            let lowercased = keyword.lowercased()
            
            if technicalIndicators.contains(where: { lowercased.contains($0) }) || 
               project.techStack.contains(where: { $0.lowercased().contains(lowercased) }) {
                technical.append(keyword)
            } else if businessIndicators.contains(where: { lowercased.contains($0) }) {
                business.append(keyword)
            } else if project.targetAudience.lowercased().contains(lowercased) {
                audience.append(keyword)
            } else {
                // Default to business if unclear
                business.append(keyword)
            }
        }
        
        return [
            "technical": technical,
            "business": business,
            "audience": audience
        ]
    }
    
    private func generateSummaryExtension(from keywordGroups: [String: [String]], project: Project) -> String {
        let technical = keywordGroups["technical"] ?? []
        let business = keywordGroups["business"] ?? []
        
        var summary = ""
        
        // Technical summary if we have technical keywords
        if !technical.isEmpty {
            let techTerms = technical.prefix(3).joined(separator: ", ")
            summary += "From a technical perspective, this project involves \(techTerms). "
            
            if !project.techStack.isEmpty {
                let mainTech = project.techStack.prefix(2).joined(separator: " and ")
                summary += "It leverages \(mainTech) to deliver a robust solution. "
            }
        }
        
        // Business summary
        if !business.isEmpty {
            let businessTerms = business.prefix(3).joined(separator: ", ")
            summary += "The project addresses business needs related to \(businessTerms). "
        }
        
        // Add feature highlight
        if !project.coreFeatures.isEmpty {
            let featuresCount = project.coreFeatures.count
            summary += "With \(featuresCount) core feature\(featuresCount > 1 ? "s" : ""), the solution will provide comprehensive functionality to meet user requirements. "
        }
        
        return summary
    }
    
    // Helper types for technical document generation
    private struct ProjectComplexity {
        let level: Int // 1-5 where 5 is most complex
        let description: String
        let developmentEffort: String
        let recommendedApproach: String
    }
    
    private struct TechRecommendations {
        let frontend: String
        let backend: String
        let storage: String
        let authentication: String
        let privacy: String
        let performance: String
    }
    
    private func calculateProjectComplexity(_ project: Project) -> ProjectComplexity {
        // Calculate complexity based on number of features, tech stack, and target audience
        let featureCount = project.coreFeatures.count
        let techStackCount = project.techStack.count
        let hasComplexAudience = project.targetAudience.lowercased().contains("enterprise") || 
                                 project.targetAudience.lowercased().contains("professional")
        
        // Calculate base complexity score
        var complexityScore = 1
        
        if featureCount > 10 {
            complexityScore += 2
        } else if featureCount > 5 {
            complexityScore += 1
        }
        
        if techStackCount > 8 {
            complexityScore += 2
        } else if techStackCount > 4 {
            complexityScore += 1
        }
        
        if hasComplexAudience {
            complexityScore += 1
        }
        
        // Cap at level 5
        complexityScore = min(complexityScore, 5)
        
        // Create appropriate descriptions based on complexity
        let descriptions = [
            "minimal",
            "low",
            "moderate",
            "significant",
            "high"
        ]
        
        let efforts = [
            "1-2 weeks",
            "2-4 weeks",
            "1-2 months",
            "2-3 months",
            "3+ months"
        ]
        
        let approaches = [
            "Rapid prototyping with minimal planning phase",
            "Agile approach with weekly iterations",
            "Agile development with thorough planning phase",
            "Structured development with detailed technical specifications",
            "Comprehensive planning and phased development approach"
        ]
        
        return ProjectComplexity(
            level: complexityScore,
            description: descriptions[complexityScore - 1],
            developmentEffort: efforts[complexityScore - 1],
            recommendedApproach: approaches[complexityScore - 1]
        )
    }
    
    private func generateTechnologyRecommendations(_ project: Project) -> TechRecommendations {
        // Frontend recommendation
        let frontendTech = project.techStack.filter { $0.lowercased().contains("ui") || $0.lowercased().contains("front") }
        let frontend: String
        if frontendTech.isEmpty {
            frontend = """
            - Primary UI Framework: SwiftUI
            - Design System: Apple Human Interface Guidelines
            - Responsive Design: Adaptable layouts for iPhone and iPad
            - Accessibility: VoiceOver support and Dynamic Type
            """
        } else {
            frontend = """
            - Primary UI Framework: \(frontendTech.joined(separator: ", "))
            - Design System: Apple Human Interface Guidelines
            - Responsive Design: Adaptable layouts for iPhone and iPad
            - Accessibility: VoiceOver support and Dynamic Type
            """
        }
        
        // Backend recommendation
        let backendTech = project.techStack.filter { $0.lowercased().contains("kit") || $0.lowercased().contains("framework") }
        let backend: String
        if backendTech.isEmpty {
            backend = """
            - Core Frameworks: Foundation, NaturalLanguage, PDFKit
            - Business Logic: Swift with MVVM architecture
            - Document Processing: Custom text processing engine
            """
        } else {
            backend = """
            - Core Frameworks: \(backendTech.joined(separator: ", "))
            - Business Logic: Swift with MVVM architecture
            - Document Processing: Custom text processing engine
            """
        }
        
        // Storage recommendation
        let storageTech = project.techStack.filter { $0.lowercased().contains("data") || $0.lowercased().contains("store") || $0.lowercased().contains("file") }
        let storage: String
        if storageTech.isEmpty {
            storage = """
            - Primary Storage: FileManager for document storage
            - Format: JSON for structured data, PDF for generated documents
            - Backup: Local backup and restore functionality
            - Search: Indexed content for fast local search
            """
        } else {
            storage = """
            - Primary Storage: \(storageTech.joined(separator: ", "))
            - Format: JSON for structured data, PDF for generated documents
            - Backup: Local backup and restore functionality
            - Search: Indexed content for fast local search
            """
        }
        
        // Authentication recommendation
        let needsAuth = project.targetAudience.lowercased().contains("private") || 
                        project.targetAudience.lowercased().contains("enterprise") ||
                        project.description.lowercased().contains("secure")
        let authentication = needsAuth ? 
            """
            - Authentication Method: Local biometric (Face ID/Touch ID)
            - Document Security: Optional password protection for PDFs
            - Access Control: Local user preferences for security settings
            """ : 
            """
            - Authentication Method: Not required (optional for enhanced security)
            - Document Security: Optional password protection for PDFs
            - Access Control: Basic user preferences
            """
        
        // Privacy recommendation
        let privacy = """
        All data stored locally on device with no external transmission. No analytics or telemetry collected. Complete user control over data with ability to delete all content.
        """
        
        // Performance recommendation
        let performance = """
        UI responsiveness is critical for a positive user experience. Document generation should complete within 3 seconds, with progress indication for large documents. Memory usage should be optimized for mobile devices.
        """
        
        return TechRecommendations(
            frontend: frontend,
            backend: backend,
            storage: storage,
            authentication: authentication,
            privacy: privacy,
            performance: performance
        )
    }
    
    private func generateSecurityRecommendations(_ project: Project) -> String {
        // Check project characteristics to determine security needs
        let hasConfidentialData = project.description.lowercased().contains("confidential") ||
                                 project.description.lowercased().contains("secure") ||
                                 project.description.lowercased().contains("private")
        
        let enterpriseAudience = project.targetAudience.lowercased().contains("enterprise") ||
                                 project.targetAudience.lowercased().contains("business") ||
                                 project.targetAudience.lowercased().contains("professional")
        
        if hasConfidentialData || enterpriseAudience {
            return """
            This application handles potentially sensitive information and should implement the following security measures:
            
            - Data Encryption: Use FileProtection API to encrypt stored documents
            - Authentication: Implement biometric authentication (Face ID/Touch ID) for app access
            - Document Security: Provide option for password-protected PDFs
            - Secure Defaults: Enable security features by default
            - Data Isolation: Ensure app data is sandboxed properly
            - Export Warnings: Notify users when exporting sensitive documents
            - Session Management: Auto-lock after period of inactivity
            """
        } else {
            return """
            While this application primarily handles non-sensitive information, basic security practices should be implemented:
            
            - Data Isolation: Ensure app data is properly sandboxed
            - Export Controls: Clear user confirmations for document sharing
            - Optional Security: Provide user options to enable additional security features
            - Privacy First: No data collection or external transmission
            - Transparency: Clear documentation of all data storage practices
            """
        }
    }
} 