import SwiftUI
import UIKit

// Move enum outside the struct so it's accessible to extensions
enum APITestResult {
    case success
    case failure(String)
}

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showResetAlert = false
    @State private var showOpenAIAlert = false
    @State private var openAIKey = ""
    @State private var tempOpenAIKey = ""
    @State private var useOpenAI = false
    @State private var isTestingAPI = false
    @State private var apiTestResult: APITestResult? = nil
    @Environment(\.colorScheme) var colorScheme
    @State private var refreshView = false // Trigger view updates
    
    var body: some View {
        ZStack {
            // Background color
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // App Header
                    appHeader
                    
                    // Main Settings
                    VStack(spacing: 20) {
                        appearanceSection
                        
                        openAISection
                        
                        dataManagementSection
                        
                        aboutSection
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Settings")
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset All Data"),
                message: Text("Are you sure you want to delete all projects and documents? This action cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    resetAllData()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("OpenAI API Key", isPresented: $showOpenAIAlert) {
            TextField("Enter API Key", text: $tempOpenAIKey)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
            
            Button("Cancel", role: .cancel) {
                tempOpenAIKey = ""
            }
            
            Button("Save") {
                handleSaveAPIKey()
            }
        } message: {
            Text("Enter your OpenAI API key to enable AI-powered document generation. You can get an API key from platform.openai.com.")
        }
        .onAppear {
            // Initialize the useOpenAI toggle based on current mode
            useOpenAI = DocumentGenerator.shared.getGenerationMode() == .openAI
            print("onAppear: Mode is \(DocumentGenerator.shared.getGenerationMode() == .openAI ? "OpenAI" : "Offline")")
        }
        .id(refreshView) // Force view refresh when this changes
    }
    
    // MARK: - View Components
    
    private var appHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.gearshape")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("DocuForge Settings")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Configure your document generation preferences")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Appearance", icon: "paintbrush")
            
            VStack {
                Toggle(isOn: $isDarkMode) {
                    HStack {
                        Image(systemName: isDarkMode ? "moon.fill" : "moon")
                            .foregroundColor(isDarkMode ? .purple : .gray)
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dark Mode")
                                .fontWeight(.medium)
                            
                            Text(isDarkMode ? "Currently enabled" : "Currently disabled")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .padding(.vertical, 5)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .settingsSectionStyle()
    }
    
    private var openAISection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "AI Document Generation", icon: "brain.head.profile")
            
            VStack(spacing: 16) {
                // OpenAI Toggle
                Toggle(isOn: $useOpenAI) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(useOpenAI ? .blue : .gray)
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Use OpenAI")
                                .fontWeight(.medium)
                            
                            Text(useOpenAI ? "AI-powered documents" : "Basic document templates")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: useOpenAI) { newValue in
                    if newValue {
                        if OpenAIService.shared.isConfigured {
                            DocumentGenerator.shared.setGenerationMode(.openAI)
                            print("Setting mode to OpenAI in toggle")
                        } else {
                            showOpenAIAlert = true
                            useOpenAI = false
                        }
                    } else {
                        DocumentGenerator.shared.setGenerationMode(.offline)
                        print("Setting mode to Offline in toggle")
                    }
                    refreshView.toggle() // Force refresh
                }
                
                Divider()
                
                // API Key Button
                Button(action: {
                    tempOpenAIKey = OpenAIService.shared.isConfigured ? "" : ""
                    showOpenAIAlert = true
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Configure OpenAI API Key")
                                .fontWeight(.medium)
                            
                            Text(OpenAIService.shared.isConfigured ? "API key is configured" : "API key not set")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.systemGray4))
                    }
                }
                
                Divider()
                
                // Test API Button
                Button(action: {
                    testOpenAIConnection()
                }) {
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Test API Connection")
                                .fontWeight(.medium)
                            
                            if isTestingAPI {
                                Text("Testing...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if let result = apiTestResult {
                                switch result {
                                case .success:
                                    Text("Connection successful")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                case .failure(let message):
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            } else {
                                Text("Verify your OpenAI connection")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if isTestingAPI {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else if let result = apiTestResult {
                            Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.isSuccess ? .green : .red)
                        }
                    }
                }
                .disabled(isTestingAPI || !OpenAIService.shared.isConfigured)
                .opacity(OpenAIService.shared.isConfigured ? 1.0 : 0.6)
                
                // API Status Card
                if OpenAIService.shared.isConfigured {
                    apiStatusCard
                } else {
                    noAPIKeyCard
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .settingsSectionStyle()
    }
    
    private var apiStatusCard: some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Label {
                        Text("API Status")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } icon: {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                    }
                    
                    HStack(spacing: 12) {
                        statusItem(
                            title: "API Key",
                            value: "Configured",
                            icon: "key.fill",
                            color: .green
                        )
                        
                        statusItem(
                            title: "Mode",
                            value: DocumentGenerator.shared.getGenerationMode() == .openAI ? "OpenAI" : "Offline",
                            icon: DocumentGenerator.shared.getGenerationMode() == .openAI ? "network" : "wifi.slash",
                            color: DocumentGenerator.shared.getGenerationMode() == .openAI ? .blue : .orange
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.green.opacity(0.1))
            )
        }
    }
    
    private var noAPIKeyCard: some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Label {
                        Text("API Not Configured")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } icon: {
                        Image(systemName: "exclamationmark.shield")
                            .foregroundColor(.orange)
                    }
                    
                    Text("To enable AI-powered document generation:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Get an API key from OpenAI")
                        bulletPoint("Enter it in the settings above")
                        bulletPoint("Enable 'Use OpenAI' toggle")
                    }
                    
                    Button(action: {
                        openOpenAIWebsite()
                    }) {
                        Text("Visit OpenAI.com")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.1))
            )
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.orange)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func statusItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
        }
        .frame(minWidth: 80, alignment: .leading)
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Data Management", icon: "externaldrive")
            
            VStack {
                Button(action: {
                    showResetAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reset All Data")
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            
                            Text("Delete all projects and documents")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(.systemGray4))
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .settingsSectionStyle()
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "About", icon: "info.circle")
            
            VStack(spacing: 16) {
                // App info
                VStack(spacing: 8) {
                    infoRow(label: "Version", value: "1.0.0")
                    infoRow(label: "Build", value: "1")
                    infoRow(
                        label: "Privacy",
                        value: OpenAIService.shared.isConfigured ? "Online/Offline" : "100% Offline",
                        valueColor: OpenAIService.shared.isConfigured ? .orange : .green
                    )
                }
                
                Divider()
                
                // App description
                VStack(alignment: .leading, spacing: 12) {
                    Text("DocuForge")
                        .font(.headline)
                    
                    Text("DocuForge is an app for generating project documentation from your inputs. It works offline by default, but can also connect to OpenAI for enhanced document generation when configured.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Divider()
                
                Text("DocuForge © 2023")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
            )
        }
        .settingsSectionStyle()
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
    
    private func infoRow(label: String, value: String, valueColor: Color = .secondary) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(valueColor)
        }
    }
    
    // MARK: - Actions
    
    private func handleSaveAPIKey() {
        if tempOpenAIKey.isEmpty {
            // Clear API key
            OpenAIService.shared.clearAPIKey()
            DocumentGenerator.shared.setGenerationMode(.offline)
            useOpenAI = false
            apiTestResult = nil
            print("Cleared API key and set mode to Offline")
        } else {
            // Save API key
            OpenAIService.shared.saveAPIKey(tempOpenAIKey)
            DocumentGenerator.shared.setGenerationMode(.openAI)
            useOpenAI = true
            print("Saved API key and set mode to OpenAI")
            
            // Test the API connection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                testOpenAIConnection()
            }
        }
        tempOpenAIKey = ""
        refreshView.toggle() // Force refresh
    }
    
    private func testOpenAIConnection() {
        guard OpenAIService.shared.isConfigured else {
            apiTestResult = .failure("API key not configured")
            return
        }
        
        isTestingAPI = true
        apiTestResult = nil
        
        OpenAIService.shared.testConnection { result in
            DispatchQueue.main.async {
                isTestingAPI = false
                switch result {
                case .success:
                    apiTestResult = .success
                case .failure(let error):
                    apiTestResult = .failure(error.localizedDescription)
                }
                refreshView.toggle() // Force refresh
            }
        }
    }
    
    private func openOpenAIWebsite() {
        if let url = URL(string: "https://platform.openai.com/api-keys") {
            UIApplication.shared.open(url)
        }
    }
    
    private func resetAllData() {
        // Get all projects
        let projects = ProjectManager.shared.loadProjects()
        
        // Delete each project
        for project in projects {
            ProjectManager.shared.deleteProject(project)
        }
    }
}

// MARK: - Extensions

extension APITestResult {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}

extension View {
    func settingsSectionStyle() -> some View {
        self.padding(.vertical, 8)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
        }
    }
} 

