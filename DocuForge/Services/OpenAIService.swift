import Foundation

enum OpenAIError: Error {
    case invalidConfiguration
    case networkError(Error)
    case apiError(String)
    case decodingError
}

class OpenAIService {
    // Singleton instance
    static let shared = OpenAIService()
    
    private let apiKeyKey = "openai_api_key"
    private var apiKey: String?
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let session: URLSession
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpMaximumConnectionsPerHost = 4
        self.session = URLSession(configuration: configuration)
        // Load saved API key on initialization
        loadAPIKey()
    }
    
    // MARK: - Public Methods
    
    var isConfigured: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    // Save API key to secure storage
    func saveAPIKey(_ key: String) {
        // In a real app, this would use Keychain
        UserDefaults.standard.set(key, forKey: apiKeyKey)
        loadAPIKey()
    }
    
    // Clear the API key
    func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
        apiKey = nil
    }
    
    // Load the API key
    private func loadAPIKey() {
        // In a real app, this would use Keychain
        apiKey = UserDefaults.standard.string(forKey: apiKeyKey)
    }
    
    // Test API connection
    func testConnection(completion: @escaping (Result<Void, OpenAIError>) -> Void) {
        guard isConfigured else {
            completion(.failure(.invalidConfiguration))
            return
        }
        
        // Create a minimal request to test the API connection
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        request.httpMethod = "GET"
        request.addValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        print("[OpenAIService] testConnection -> GET /v1/models")
        performRequest(request, retryCount: 3) { result in
            switch result {
            case .success((let data, let httpResponse)):
                if httpResponse.statusCode == 200 {
                    completion(.success(()))
                } else if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    completion(.failure(.apiError(errorResponse.error.message)))
                } else {
                    completion(.failure(.apiError("Error code: \(httpResponse.statusCode)")))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // Generate document content using OpenAI
    func generateDocument(for project: Project, type: DocumentType, completion: @escaping (Result<String, OpenAIError>) -> Void) {
        guard isConfigured else {
            completion(.failure(.invalidConfiguration))
            return
        }
        
        // Prepare the API request
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare prompt based on document type
        let prompt = createPromptForDocument(project: project, documentType: type)
        
        // Create request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a professional document generator for software and business projects. Create detailed, well-structured documents in Markdown format."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2500
        ]
        
        // Convert request body to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(.apiError("Failed to create request")))
            return
        }
        
        request.httpBody = jsonData
        
        print("[OpenAIService] generateDocument -> POST /v1/chat/completions for document type: \(type.rawValue)")
        performRequest(request, retryCount: 3) { result in
            switch result {
            case .success((let data, _)):
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = jsonResponse["choices"] as? [[String: Any]],
                       let firstChoice = choices.first,
                       let message = firstChoice["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        completion(.success(content))
                    } else if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                        completion(.failure(.apiError(errorResponse.error.message)))
                    } else {
                        completion(.failure(.decodingError))
                    }
                } catch {
                    completion(.failure(.decodingError))
                }
            case .failure(let err):
                completion(.failure(err))
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createPromptForDocument(project: Project, documentType: DocumentType) -> String {
        // Base project information
        var prompt = """
        Generate a professional \(documentType.rawValue) document in markdown format for the following project:
        
        Project Name: \(project.name)
        Description: \(project.description)
        Goal: \(project.goal)
        Target Audience: \(project.targetAudience)
        Launch Date: \(project.formattedLaunchDate)
        Core Features:
        \(project.coreFeatures.map { "- \($0)" }.joined(separator: "\n"))
        
        Tech Stack:
        \(project.techStack.map { "- \($0)" }.joined(separator: "\n"))
        
        Client Notes: \(project.clientNotes)
        
        """
        
        // Add specific instructions based on document type
        switch documentType {
        case .projectSummary:
            prompt += """
            For this PROJECT SUMMARY, include:
            - An executive summary
            - Project vision and objectives
            - Key stakeholders
            - Target audience analysis
            - Core feature highlights
            - Technology overview
            - Value proposition
            - Format with clear headings and professional language
            """
            
        case .technicalRequirements:
            prompt += """
            For this TECHNICAL REQUIREMENTS document, include:
            - System architecture overview
            - Detailed backend requirements
            - Frontend/UI requirements
            - API specifications if applicable
            - Database schema and data flow
            - Security requirements
            - Performance requirements
            - Compatibility requirements
            - Technical dependencies and third-party integrations
            - Development environment setup
            - Use professional, technical language
            """
            
        case .functionalSpecs:
            prompt += """
            For this FUNCTIONAL SPECIFICATIONS document, include:
            - Detailed description of each feature
            - User flows for key functionality
            - User roles and permissions
            - Business rules and logic
            - Input validation rules
            - Error handling scenarios
            - Integration points
            - Acceptance criteria for each feature
            - Use clear, specific language with examples where helpful
            """
            
        case .timeline:
            prompt += """
            For this PROJECT TIMELINE document, include:
            - Project phases (Planning, Development, Testing, Deployment)
            - Key milestones with estimated dates
            - Dependencies between tasks
            - Resource allocation recommendations
            - Risk assessment and contingency plans
            - Critical path analysis
            - Progress tracking methodology
            - Create a realistic timeline based on the project complexity
            """
            
        case .nda:
            prompt += """
            For this NON-DISCLOSURE AGREEMENT document, include:
            - Professional legal language for an NDA
            - Definition of confidential information specific to this project
            - Obligations of receiving party
            - Exclusions from confidential information
            - Term and termination conditions
            - Return of materials clause
            - Governing law
            - Remedies for breach
            - Signature blocks
            - Format as a formal legal document while keeping it in markdown
            """
        }
        
        // Add final instructions
        prompt += """
        
        Format the document professionally with proper markdown headings, bullet points, and sections.
        Include a title, introduction, and conclusion.
        Use clear, concise language appropriate for a business document.
        """
        
        return prompt
    }
}

// Structure for parsing OpenAI error responses
struct OpenAIErrorResponse: Codable {
    let error: OpenAIErrorDetail
}

struct OpenAIErrorDetail: Codable {
    let message: String
    let type: String?
    let param: String?
    let code: String?
} 

// MARK: - Networking helpers
extension OpenAIService {
    private func performRequest(_ request: URLRequest,
                                retryCount: Int,
                                completion: @escaping (Result<(Data, HTTPURLResponse), OpenAIError>) -> Void) {
        let urlString = request.url?.absoluteString ?? "<unknown>"
        let attempt = 4 - max(retryCount, 0)
        print("[OpenAIService] Request attempt #\(attempt) -> \(urlString)")
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                if self.isTransientNetworkError(error), retryCount > 0 {
                    let delay = self.backoffDelay(forRemainingRetries: retryCount)
                    print("[OpenAIService] Transient error: \(error.localizedDescription). Retrying in \(String(format: "%.2f", delay))s (remaining: \(retryCount))")
                    DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                        self.performRequest(request, retryCount: retryCount - 1, completion: completion)
                    }
                    return
                } else {
                    print("[OpenAIService] Network error (no retry): \(error.localizedDescription)")
                    completion(.failure(.networkError(error)))
                    return
                }
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.apiError("Invalid response")))
                return
            }
            guard let data = data else {
                completion(.failure(.apiError("No data received")))
                return
            }
            completion(.success((data, httpResponse)))
        }
        task.resume()
    }
    
    private func isTransientNetworkError(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        switch nsError.code {
        case NSURLErrorTimedOut,                 // -1001
             NSURLErrorCannotFindHost,           // -1003
             NSURLErrorCannotConnectToHost,      // -1004
             NSURLErrorNetworkConnectionLost,    // -1005
             NSURLErrorDNSLookupFailed,          // -1006
             NSURLErrorNotConnectedToInternet:   // -1009
            return true
        default:
            return false
        }
    }
    
    private func backoffDelay(forRemainingRetries retries: Int) -> TimeInterval {
        // Exponential backoff with jitter: base 0.5s, max ~4s
        let attemptIndex = 4 - max(retries, 0) // 1-based attempt number
        let base: TimeInterval = 0.5
        let maxDelay = min(4.0, pow(2.0, Double(attemptIndex - 1)) * base)
        let jitter = Double.random(in: 0...(base))
        return min(4.0, maxDelay + jitter)
    }
}
