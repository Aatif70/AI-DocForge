import SwiftUI
import UIKit
import PDFKit

struct ProjectDetailView: View {
    var project: Project
    @State private var selectedTab = 0
    @State private var documents: [Document] = []
    @State private var showShareSheet = false
    @State private var shareURL: URL?
    @State private var isGenerating = false
    @State private var showDeleteAlert = false
    @State private var currentDocumentContent: String = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var documentGenProgress: Double = 0
    @State private var isSharingDocument = false
    
    private let pdfGenerator = PDFGenerator()
    
    var documentTypes: [DocumentType] {
        return DocumentType.allCases
    }
    
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Project header
                projectHeader
                
                // Tab selector
                tabSelector
                
                // Document content
                ZStack {
                    // Document content
                    documentContentView
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    
                    // Generation overlay
                    if isGenerating {
                        generationOverlay
                    }
                }
                
                // Action buttons
                actionButtons
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadDocuments()
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete Project"),
                message: Text("Are you sure you want to delete this project? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteProject()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - View Components
    
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Project description
            Text(project.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.bottom, 4)
            
            HStack(spacing: 16) {
                // Goal section
                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text("Goal")
                            .font(.caption)
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "target")
                            .foregroundColor(.blue)
                    }
                    Text(project.goal)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Launch date section
                VStack(alignment: .trailing, spacing: 4) {
                    Label {
                        Text("Launch Date")
                            .font(.caption)
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "calendar")
                            .foregroundColor(.green)
                    }
                    Text(project.formattedLaunchDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<documentTypes.count, id: \.self) { index in
                    tabButton(title: documentTypes[index].rawValue, isSelected: selectedTab == index, index: index)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(
            Rectangle()
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
        )
    }
    
    private func tabButton(title: String, isSelected: Bool, index: Int) -> some View {
        let hasDocument = project.documents.contains(where: { $0.type == documentTypes[index] })
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = index
            }
            loadCurrentDocumentContent()
        }) {
            VStack(spacing: 8) {
                // Document type icon based on the document type
                Image(systemName: iconForDocumentType(documentTypes[index]))
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Indicator
                if isSelected {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 30, height: 3)
                        .transition(.scale)
                } else if hasDocument {
                    Capsule()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 20, height: 3)
                        .transition(.scale)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 3)
                }
            }
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func iconForDocumentType(_ type: DocumentType) -> String {
        switch type {
        case .projectSummary:
            return "doc.text"
        case .technicalRequirements:
            return "wrench.and.screwdriver"
        case .functionalSpecs:
            return "list.bullet.clipboard"
        case .timeline:
            return "calendar.badge.clock"
        case .nda:
            return "lock.doc"
        }
    }
    
    private var documentContentView: some View {
        ScrollView {
            if let document = project.documents.first(where: { $0.type == documentTypes[selectedTab] }) {
                // Display existing document with metadata
                VStack(alignment: .leading, spacing: 16) {
                    // Document metadata header
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.purple.opacity(0.7))
                                    .font(.caption)
                                
                                Text("Created: \(formattedDate(document.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if document.lastModified != document.createdAt {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .foregroundColor(.orange.opacity(0.7))
                                        .font(.caption)
                                    
                                    Text("Updated: \(formattedDate(document.lastModified))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            HStack {
                                Image(systemName: "text.word.count")
                                    .foregroundColor(.blue.opacity(0.7))
                                    .font(.caption)
                                
                                Text("\(document.wordCount) words")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.green.opacity(0.7))
                                    .font(.caption)
                                
                                Text("\(document.readingTime) min read")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Key points (if available)
                    if !document.keyPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Points")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            ForEach(document.keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 14))
                                    
                                    Text(point)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.leading, 4)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor.opacity(0.08))
                        )
                    }
                    
                    // Document content
                    Text(document.content)
                        .font(.body)
                        .padding(.top, 8)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
            } else {
                // Display document placeholder
                VStack(spacing: 24) {
                    Image(systemName: iconForDocumentType(documentTypes[selectedTab]))
                        .font(.system(size: 60))
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    Text("No \(documentTypes[selectedTab].rawValue) Yet")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("Generate a \(documentTypes[selectedTab].rawValue) using OpenAI to create comprehensive documentation for this project.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        generateCurrentDocument()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate with AI")
                            Image(systemName: "sparkles")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
            }
        }
    }
    
    private var generationOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                LottieView(name: "document_generation")
                    .frame(width: 120, height: 120)
                
                Text("Generating Your Document")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Using OpenAI to create your document...")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                ProgressView(value: documentGenProgress, total: 100)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white))
                    .frame(width: 200)
                
                if documentGenProgress == 0 {
                    // Show animation when progress is indeterminate
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 8)
                }
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.accentColor.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .onAppear {
                // Simulate progress for better UX
                documentGenProgress = 0
                withAnimation(.easeInOut(duration: 0.5).delay(0.5)) {
                    documentGenProgress = 30
                }
                
                withAnimation(.easeInOut(duration: 0.8).delay(1.5)) {
                    documentGenProgress = 60
                }
                
                withAnimation(.easeInOut(duration: 1.2).delay(3)) {
                    documentGenProgress = 90
                }
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button(action: {
                showDeleteAlert = true
            }) {
                VStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                    
                    Text("Delete")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
                .frame(width: 50, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                )
            }
            
            Button(action: {
                generateCurrentDocument()
            }) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                    Text(project.documents.contains(where: { $0.type == documentTypes[selectedTab] }) ? "Regenerate" : "Generate")
                        .fontWeight(.semibold)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            
            if let document = project.documents.first(where: { $0.type == documentTypes[selectedTab] }),
               let pdfPath = document.pdfPath {
                Button(action: {
                    isSharingDocument = true
                    let url = URL(fileURLWithPath: pdfPath)
                    // Use a FileManager to ensure the file exists
                    if FileManager.default.fileExists(atPath: url.path) {
                        shareURL = url
                        showShareSheet = true
                    } else {
                        showError("The PDF file could not be found. Please try regenerating the document.")
                    }
                    isSharingDocument = false
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)
                        
                        Text("Share")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                    }
                    .frame(width: 50, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                    .overlay(
                        Group {
                            if isSharingDocument {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                    )
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(
            Rectangle()
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: -2)
        )
    }
    
    // MARK: - Logic Functions
    
    private func loadDocuments() {
        if let loadedProject = ProjectManager.shared.getProject(with: project.id) {
            documents = loadedProject.documents
            loadCurrentDocumentContent()
        }
    }
    
    private func loadCurrentDocumentContent() {
        if let document = project.documents.first(where: { $0.type == documentTypes[selectedTab] }) {
            currentDocumentContent = document.content
        } else {
            currentDocumentContent = ""
        }
    }
    
    private func generateCurrentDocument() {
        // Check if we need to use OpenAI but it's not configured
        if DocumentGenerator.shared.getGenerationMode() == .openAI && !DocumentGenerator.shared.canUseOpenAI() {
            self.showError("OpenAI is not configured. Please go to Settings to add your API key.")
            return
        }
        
        // Show loading overlay
        isGenerating = true
        documentGenProgress = 0
        
        // Determine document type
        let documentType = documentTypes[selectedTab]
        let fileName = "\(project.name) - \(documentType.rawValue)"
        
        // Generate document content using the singleton
        DocumentGenerator.shared.generateDocument(for: project, type: documentType) { content in
            // Ensure we stay on the loading screen for at least 2 seconds for UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    documentGenProgress = 95
                }
            }
            
            // Generate PDF on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                if let pdfURL = self.pdfGenerator.generatePDF(from: content, fileName: fileName) {
                    // Update the project in the database on main thread
                    DispatchQueue.main.async {
                        if let updatedProject = ProjectManager.shared.updateProjectDocument(
                            projectID: self.project.id,
                            documentType: documentType,
                            content: content,
                            pdfPath: pdfURL.path
                        ) {
                            // Update the local documents array
                            withAnimation {
                                documentGenProgress = 100
                            }
                            
                            // Wait a moment to show completion before dismissing
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.documents = updatedProject.documents
                                self.currentDocumentContent = content
                                self.isGenerating = false
                            }
                        } else {
                            self.isGenerating = false
                            self.showError("Failed to update project document.")
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isGenerating = false
                        self.showError("Failed to generate PDF.")
                    }
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    private func deleteProject() {
        ProjectManager.shared.deleteProject(project)
        // Navigate back to home screen
        // This happens automatically when the project is deleted since the navigation link breaks
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// LottieView for animation
struct LottieView: UIViewRepresentable {
    var name: String
    
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView()
        // We're just using a placeholder view
        // In a real implementation, you would add a Lottie animation here
        let label = UILabel()
        label.text = "AI"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 40, weight: .bold)
        label.textColor = .white
        view.addSubview(label)
        label.frame = view.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {}
}

// ShareSheet view to share PDFs
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ProjectDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleProject = Project(
            name: "Sample Project",
            description: "A sample project for preview",
            goal: "To test the app",
            targetAudience: "Developers",
            coreFeatures: ["Feature 1", "Feature 2"],
            techStack: ["SwiftUI", "Swift"],
            launchDate: Date().addingTimeInterval(60*60*24*30),
            clientNotes: "Some notes"
        )
        
        return NavigationView {
            ProjectDetailView(project: sampleProject)
        }
    }
} 