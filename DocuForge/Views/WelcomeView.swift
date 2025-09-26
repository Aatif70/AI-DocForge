import SwiftUI

struct WelcomeView: View {
    @State private var projects: [Project] = []
    @State private var showNewProject = false
    @State private var searchText = ""
    @State private var showSearchBar = false
    @State private var isRefreshing = false
    @Environment(\.colorScheme) var colorScheme
    
    var filteredProjects: [Project] {
        if searchText.isEmpty {
            return projects
        } else {
            return projects.filter { project in
                project.name.lowercased().contains(searchText.lowercased()) ||
                project.description.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header section
                    headerSection
                    
                    // Search bar (if active)
                    if showSearchBar {
                        searchBarView
                    }
                    
                    // Projects list section
                    if projects.isEmpty {
                        emptyProjectsView
                    } else if filteredProjects.isEmpty {
                        noSearchResultsView
                    } else {
                        projectsList
                            .refreshable {
                                withAnimation {
                                    isRefreshing = true
                                }
                                // Simulate a slight delay for better UX
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    loadProjects()
                                    withAnimation {
                                        isRefreshing = false
                                    }
                                }
                            }
                    }
                    
                    // New project button
                    newProjectButton
                }
                .padding(.horizontal)
            }
            .navigationTitle("DocuForge")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            withAnimation {
                                showSearchBar.toggle()
                                if !showSearchBar {
                                    searchText = ""
                                }
                            }
                        }) {
                            Image(systemName: showSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                                .foregroundColor(showSearchBar ? .gray : .accentColor)
                                .font(.system(size: 16))
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }
            .onAppear {
                loadProjects()
            }
            .sheet(isPresented: $showNewProject) {
                PromptInputView(isPresented: $showNewProject, projectCreated: loadProjects)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: "doc.badge.gearshape")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                    
                    Text("AI-Powered Documentation")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Label {
                        Text(projects.count > 0 ? "\(projects.count) Project\(projects.count > 1 ? "s" : "")" : "No Projects")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "folder")
                            .foregroundColor(.orange)
                    }
                    
                    Label {
                        let docCount = projects.reduce(0) { $0 + $1.documents.count }
                        Text("\(docCount) Document\(docCount != 1 ? "s" : "")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    } icon: {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            
            Divider()
                .padding(.bottom, 8)
        }
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search projects...", text: $searchText)
                .font(.body)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.bottom, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var emptyProjectsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.8))
                .symbolEffect(.bounce, options: .repeating)
            
            Text("No Projects Yet")
                .font(.title2)
                .bold()
            
            Text("Create your first project by tapping the button below and let DocuForge generate professional documentation using AI.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .padding(.vertical)
    }
    
    private var noSearchResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.8))
            
            Text("No Matching Projects")
                .font(.title3)
                .bold()
            
            Text("Try a different search term or clear the search.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                searchText = ""
            }) {
                Text("Clear Search")
                    .font(.body.bold())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .padding(.vertical)
    }
    
    private var projectsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                HStack {
                    Text(filteredProjects.count == projects.count 
                         ? "Your Projects" 
                         : "Found \(filteredProjects.count) Project\(filteredProjects.count > 1 ? "s" : "")")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
                .padding(.horizontal, 4)
                
                ForEach(filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectCard(project: project)
                            .contextMenu {
                                Button(action: {
                                    // Delete the project
                                    ProjectManager.shared.deleteProject(project)
                                    loadProjects()
                                }) {
                                    Label("Delete Project", systemImage: "trash")
                                }
                            }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.bottom, 8)
        }
    }
    
    private var newProjectButton: some View {
        Button(action: {
            showNewProject = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                    .symbolRenderingMode(.hierarchical)
                
                Text("Start New Project")
                    .fontWeight(.semibold)
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
        .padding(.vertical, 16)
    }
    
    private func loadProjects() {
        projects = ProjectManager.shared.loadProjects().sorted(by: { $0.createdAt > $1.createdAt })
    }
}

struct ProjectCard: View {
    let project: Project
    @State private var showDocumentLabels = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Project header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(dateFormatter.string(from: project.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Project status
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Launch: \(project.formattedLaunchDate)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                        )
                        .foregroundColor(.green)
                    
                    Text("\(project.coreFeatures.count) Features")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Project description
            Text(project.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .padding(.vertical, 4)
            
            // Document indicators
            VStack(alignment: .leading, spacing: 8) {
                // Document status indicators
                HStack(spacing: 12) {
                    ForEach(documentTypes, id: \.self) { type in
                        let isActive = project.documents.contains(where: { $0.type == type })
                        
                        VStack(spacing: 4) {
                            Circle()
                                .fill(isActive ? Color.green : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                            
                            Text(type.shortName)
                                .font(.system(size: 9))
                                .foregroundColor(isActive ? .primary : .secondary)
                        }
                        .onTapGesture {
                            withAnimation {
                                showDocumentLabels.toggle()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Overall completion percentage
                    let completedDocs = project.documents.count
                    let totalDocs = documentTypes.count
                    let percentage = (completedDocs * 100) / totalDocs
                    
                    Text("\(percentage)%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(colorForPercentage(percentage))
                }
                
                // Document labels (shown when tapped)
                if showDocumentLabels {
                    HStack(spacing: 8) {
                        ForEach(documentTypes, id: \.self) { type in
                            Text(type.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .transition(.opacity)
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }
    
    private func documentStatusIndicator(for type: DocumentType, active: Bool) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(active ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(type.shortName)
                .font(.system(size: 9))
                .foregroundColor(active ? .primary : .secondary)
        }
    }
    
    private func colorForPercentage(_ percentage: Int) -> Color {
        if percentage < 25 {
            return .red
        } else if percentage < 50 {
            return .orange
        } else if percentage < 100 {
            return .blue
        } else {
            return .green
        }
    }
    
    private var documentTypes: [DocumentType] {
        return DocumentType.allCases
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// Add a computed property for short document type names
extension DocumentType {
    var shortName: String {
        switch self {
        case .projectSummary:
            return "PS"
        case .technicalRequirements:
            return "TR"
        case .functionalSpecs:
            return "FS"
        case .timeline:
            return "TL"
        case .nda:
            return "NDA"
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
    }
} 
