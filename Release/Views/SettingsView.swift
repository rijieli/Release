//
//  SettingsView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var apiService = AppStoreConnectService()
    @State private var showingFilePicker = false
    @State private var testResult: String?
    @State private var isTestingConnection = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                Label("API Configuration", systemImage: "key.fill")
                    .tag(0)
                
                Label("Instructions", systemImage: "info.circle")
                    .tag(1)
            }
            .navigationTitle("Settings")
            .frame(minWidth: 200)
        } detail: {
            Group {
                switch selectedTab {
                case 0:
                    APIConfigurationView(
                        settingsManager: settingsManager,
                        apiService: apiService,
                        showingFilePicker: $showingFilePicker,
                        testResult: $testResult,
                        isTestingConnection: $isTestingConnection
                    )
                case 1:
                    InstructionsView()
                default:
                    APIConfigurationView(
                        settingsManager: settingsManager,
                        apiService: apiService,
                        showingFilePicker: $showingFilePicker,
                        testResult: $testResult,
                        isTestingConnection: $isTestingConnection
                    )
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Error", isPresented: .constant(apiService.errorMessage != nil)) {
            Button("OK") {
                apiService.errorMessage = nil
            }
        } message: {
            if let errorMessage = apiService.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            apiService.configure(
                issuerID: settingsManager.config.issuerID,
                privateKeyID: settingsManager.config.privateKeyID,
                privateKey: settingsManager.config.privateKey
            )
            
            let success = await apiService.testConnection()
            
            await MainActor.run {
                testResult = success ? "✅ Connection successful!" : "❌ Connection failed. Check your credentials."
                isTestingConnection = false
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                // Start accessing the security-scoped resource
                guard url.startAccessingSecurityScopedResource() else {
                    apiService.errorMessage = "Permission denied: Unable to access the selected file. Please try selecting the file again."
                    return
                }
                
                defer {
                    url.stopAccessingSecurityScopedResource()
                }
                
                let data = try Data(contentsOf: url)
                if let privateKeyString = String(data: data, encoding: .utf8) {
                    settingsManager.config.privateKey = privateKeyString
                } else {
                    apiService.errorMessage = "Failed to read file content. Please ensure the file is a valid .p8 private key file."
                }
            } catch {
                apiService.errorMessage = "Failed to read private key file: \(error.localizedDescription)\n\nPlease ensure:\n• The file is a valid .p8 private key file\n• You have permission to read the file\n• The file is not corrupted"
            }
            
        case .failure(let error):
            apiService.errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

struct APIConfigurationView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var apiService: AppStoreConnectService
    @Binding var showingFilePicker: Bool
    @Binding var testResult: String?
    @Binding var isTestingConnection: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Configuration")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Configure your App Store Connect API credentials to manage your apps.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                // Configuration Form
                VStack(spacing: 20) {
                    // Issuer ID
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Issuer ID", systemImage: "person.badge.key")
                            .font(.headline)
                        
                        TextField("Enter your Issuer ID", text: $settingsManager.config.issuerID)
                            .textFieldStyle(.roundedBorder)
                            .help("Your App Store Connect Issuer ID")
                    }
                    
                    // Private Key ID
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Private Key ID", systemImage: "key")
                            .font(.headline)
                        
                        TextField("Enter your Private Key ID", text: $settingsManager.config.privateKeyID)
                            .textFieldStyle(.roundedBorder)
                            .help("The ID of your private key")
                    }
                    
                    // Private Key
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Private Key", systemImage: "doc.text")
                            .font(.headline)
                        
                        HStack {
                            Button("Choose Private Key File") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            
                            if !settingsManager.config.privateKey.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Key loaded")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        
                        if !settingsManager.config.privateKey.isEmpty {
                            Text("Private key loaded successfully")
                                .font(.caption)
                                .foregroundStyle(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Status Section
                VStack(spacing: 16) {
                    HStack {
                        Label("Connection Status", systemImage: "wifi")
                            .font(.headline)
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(settingsManager.isConfigured ? .green : .red)
                                .frame(width: 12, height: 12)
                                .symbolEffect(.pulse, isActive: settingsManager.isConfigured)
                            
                            Text(settingsManager.isConfigured ? "Configured" : "Not Configured")
                                .fontWeight(.medium)
                                .foregroundStyle(settingsManager.isConfigured ? .green : .red)
                        }
                    }
                    
                    if let testResult = testResult {
                        HStack {
                            Image(systemName: testResult.contains("Success") ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(testResult.contains("Success") ? .green : .red)
                            
                            Text(testResult)
                                .font(.caption)
                                .foregroundStyle(testResult.contains("Success") ? .green : .red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(testResult.contains("Success") ? .green.opacity(0.1) : .red.opacity(0.1))
                        )
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Actions
                HStack(spacing: 12) {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!settingsManager.isConfigured || isTestingConnection)
                    .controlSize(.large)
                    
                    if isTestingConnection {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Spacer()
                    
                    Button("Save Configuration") {
                        settingsManager.saveConfig()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!settingsManager.isConfigured)
                    .controlSize(.large)
                    
                    Button("Clear") {
                        settingsManager.clearConfig()
                        testResult = nil
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                    .controlSize(.large)
                }
            }
            .padding()
        }
        .navigationTitle("API Configuration")
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            apiService.configure(
                issuerID: settingsManager.config.issuerID,
                privateKeyID: settingsManager.config.privateKeyID,
                privateKey: settingsManager.config.privateKey
            )
            
            let success = await apiService.testConnection()
            
            await MainActor.run {
                testResult = success ? "✅ Connection successful!" : "❌ Connection failed. Check your credentials."
                isTestingConnection = false
            }
        }
    }
}

struct InstructionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Setup Instructions")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Follow these steps to configure your App Store Connect API access.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 16) {
                    InstructionStep(
                        number: 1,
                        title: "Access App Store Connect",
                        description: "Go to App Store Connect → Users and Access → Keys",
                        icon: "person.badge.key"
                    )
                    
                    InstructionStep(
                        number: 2,
                        title: "Generate API Key",
                        description: "Click the '+' button to generate a new API key",
                        icon: "plus.circle"
                    )
                    
                    InstructionStep(
                        number: 3,
                        title: "Download Private Key",
                        description: "Download the private key file (.p8) to your computer",
                        icon: "arrow.down.circle"
                    )
                    
                    InstructionStep(
                        number: 4,
                        title: "Enter Credentials",
                        description: "Copy the Issuer ID and Key ID from the API key details",
                        icon: "doc.on.doc"
                    )
                    
                    InstructionStep(
                        number: 5,
                        title: "Upload Private Key",
                        description: "Use the 'Choose Private Key File' button to upload your .p8 file",
                        icon: "folder"
                    )
                    
                    InstructionStep(
                        number: 6,
                        title: "Test & Save",
                        description: "Test the connection and save your configuration",
                        icon: "checkmark.circle"
                    )
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Additional Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Important Notes")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 16)
                            
                            Text("Keep your private key file secure and never share it")
                                .font(.caption)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 16)
                            
                            Text("API keys have expiration dates - you'll need to regenerate them periodically")
                                .font(.caption)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.green)
                                .frame(width: 16)
                            
                            Text("Your credentials are stored securely on your device")
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Instructions")
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 32, height: 32)
                
                Text("\(number)")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 16)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
