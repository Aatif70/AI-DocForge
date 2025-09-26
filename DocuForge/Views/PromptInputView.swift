import SwiftUI

struct PromptInputView: View {
    @Binding var isPresented: Bool
    var projectCreated: () -> Void
    
    // Project properties
    @State private var projectName = ""
    @State private var projectDescription = ""
    @State private var projectGoal = ""
    @State private var targetAudience = ""
    @State private var coreFeatures = ""
    @State private var techStack = ""
    @State private var launchDate = Date().addingTimeInterval(60*60*24*30) // Default to 30 days from now
    @State private var clientNotes = ""
    
    // UI state properties
    @State private var currentStep = 0
    @State private var showDatePicker = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var showConfirmation = false
    
    // Animation properties
    @State private var messageOpacity = Array(repeating: 0.0, count: 9) // One for each step + confirmation
    
    // Define the prompts for each step
    private let prompts = [
        "What's the name of your project?",
        "Great! Now, can you provide a one-liner description?",
        "What's the main goal of this project?",
        "Who is the target audience for this project?",
        "What are the core features? (List them, separated by new lines)",
        "What technologies will you use? (Optional, list separated by new lines)",
        "When is the planned launch date?",
        "Any additional client notes or requirements? (Optional)"
    ]
    
    var body: some View {
        NavigationView {
            ScrollViewReader { scrollProxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ForEach(0..<min(currentStep + 1, prompts.count), id: \.self) { step in
                            promptView(for: step)
                                .id(step)
                        }
                        
                        if showConfirmation {
                            confirmationView
                                .opacity(messageOpacity[8])
                                .id(8)
                        }
                        
                        Spacer().frame(height: 100) // Extra space at bottom for keyboard
                    }
                    .padding()
                    .onChange(of: currentStep) { _ in
                        withAnimation {
                            scrollProxy.scrollTo(currentStep, anchor: .bottom)
                        }
                        // Animate the appearance of the new prompt
                        withAnimation(Animation.easeIn.delay(0.3)) {
                            messageOpacity[currentStep] = 1.0
                        }
                    }
                    .onChange(of: showConfirmation) { _ in
                        if showConfirmation {
                            withAnimation {
                                scrollProxy.scrollTo(8, anchor: .bottom)
                            }
                            withAnimation(Animation.easeIn.delay(0.3)) {
                                messageOpacity[8] = 1.0
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                // Animate the appearance of the first prompt
                withAnimation(Animation.easeIn.delay(0.3)) {
                    messageOpacity[0] = 1.0
                }
                
                // Set up keyboard notifications
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                        keyboardHeight = keyboardSize.height
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    keyboardHeight = 0
                }
            }
        }
    }
    
    // MARK: - UI Components
    
    private func promptView(for step: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Prompt message
            HStack(alignment: .top) {
                Image(systemName: "bubble.left.fill")
                    .foregroundColor(.accentColor)
                
                Text(prompts[step])
                    .padding(10)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                Spacer()
            }
            .opacity(messageOpacity[step])
            
            // Response input
            if currentStep >= step {
                inputView(for: step)
            }
        }
    }
    
    private func inputView(for step: Int) -> some View {
        Group {
            switch step {
            case 0: // Project Name
                inputTextField(text: $projectName, placeholder: "e.g., Mobile Banking App")
                    .onSubmit { advanceStep() }
            
            case 1: // Project Description
                inputTextField(text: $projectDescription, placeholder: "e.g., A secure mobile app for banking transactions")
                    .onSubmit { advanceStep() }
            
            case 2: // Project Goal
                inputTextField(text: $projectGoal, placeholder: "e.g., Provide a seamless mobile banking experience")
                    .onSubmit { advanceStep() }
            
            case 3: // Target Audience
                inputTextField(text: $targetAudience, placeholder: "e.g., Retail banking customers aged 25-45")
                    .onSubmit { advanceStep() }
            
            case 4: // Core Features
                VStack(alignment: .trailing) {
                    TextEditor(text: $coreFeatures)
                        .frame(minHeight: 120)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    if coreFeatures.isEmpty {
                        Text("e.g., Account balance check\nFunds transfer\nBill payments")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .font(.subheadline)
                    }
                    
                    Button("Continue") {
                        advanceStep()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            
            case 5: // Tech Stack
                VStack(alignment: .trailing) {
                    TextEditor(text: $techStack)
                        .frame(minHeight: 100)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    if techStack.isEmpty {
                        Text("e.g., SwiftUI\nNaturalLanguage\nPDFKit")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .font(.subheadline)
                    }
                    
                    Button("Continue") {
                        advanceStep()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            
            case 6: // Launch Date
                VStack {
                    if showDatePicker {
                        DatePicker("Launch Date", selection: $launchDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        if showDatePicker {
                            advanceStep()
                        }
                        withAnimation {
                            showDatePicker.toggle()
                        }
                    }) {
                        HStack {
                            if !showDatePicker {
                                Image(systemName: "calendar")
                                Text("Select Launch Date")
                            } else {
                                Text("Confirm: \(formattedDate(launchDate))")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 5)
            
            case 7: // Client Notes
                VStack(alignment: .trailing) {
                    TextEditor(text: $clientNotes)
                        .frame(minHeight: 100)
                        .padding(10)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    if clientNotes.isEmpty {
                        Text("Any additional notes or requirements...")
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .font(.subheadline)
                    }
                    
                    Button("Generate Documents") {
                        showConfirmation = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            
            default:
                EmptyView()
            }
        }
        .padding(.leading, 30)
        .animation(.easeInOut, value: step)
    }
    
    private var confirmationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Group {
                Text("Project Details Summary")
                    .font(.headline)
                
                summaryRow(title: "Name", value: projectName)
                summaryRow(title: "Description", value: projectDescription)
                summaryRow(title: "Goal", value: projectGoal)
                summaryRow(title: "Audience", value: targetAudience)
                summaryRow(title: "Launch Date", value: formattedDate(launchDate))
                
                Text("Core Features:")
                    .fontWeight(.medium)
                Text(coreFeatures.isEmpty ? "None specified" : coreFeatures)
                    .foregroundColor(.secondary)
                    .padding(.leading, 5)
                
                Text("Tech Stack:")
                    .fontWeight(.medium)
                Text(techStack.isEmpty ? "None specified" : techStack)
                    .foregroundColor(.secondary)
                    .padding(.leading, 5)
                
                if !clientNotes.isEmpty {
                    Text("Client Notes:")
                        .fontWeight(.medium)
                    Text(clientNotes)
                        .foregroundColor(.secondary)
                        .padding(.leading, 5)
                }
            }
            
            HStack {
                Button("Edit") {
                    showConfirmation = false
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Spacer()
                
                Button("Create Project") {
                    createProject()
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(.top)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func summaryRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(title):")
                .fontWeight(.medium)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private func inputTextField(text: Binding<String>, placeholder: String) -> some View {
        HStack {
            TextField(placeholder, text: text)
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(8)
                .submitLabel(.next)
            
            if !text.wrappedValue.isEmpty {
                Button(action: advanceStep) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
    
    // MARK: - Logic Functions
    
    private func advanceStep() {
        // Validate current step
        let isValid = validateCurrentStep()
        
        if isValid && currentStep < prompts.count - 1 {
            currentStep += 1
        } else if isValid {
            showConfirmation = true
        }
    }
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 0: return !projectName.isEmpty
        case 1: return !projectDescription.isEmpty
        case 2: return !projectGoal.isEmpty
        case 3: return !targetAudience.isEmpty
        case 4: return !coreFeatures.isEmpty
        case 5: return true // Tech stack is optional
        case 6: return true // Launch date is pre-filled
        case 7: return true // Client notes are optional
        default: return true
        }
    }
    
    private func createProject() {
        // Process features and tech stack strings into arrays
        let featuresArray = coreFeatures.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        let techStackArray = techStack.split(separator: "\n").map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        
        // Create the project
        let project = Project(
            name: projectName,
            description: projectDescription,
            goal: projectGoal,
            targetAudience: targetAudience,
            coreFeatures: featuresArray,
            techStack: techStackArray,
            launchDate: launchDate,
            clientNotes: clientNotes
        )
        
        // Save the project
        ProjectManager.shared.saveProject(project)
        
        // Call the completion handler
        projectCreated()
        
        // Dismiss the sheet
        isPresented = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct PromptInputView_Previews: PreviewProvider {
    static var previews: some View {
        PromptInputView(isPresented: .constant(true), projectCreated: {})
    }
} 