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
    @StateObject private var apiService = AppStoreConnectService.shared
    @State private var showingFilePicker = false
    @State private var testResult: String?
    @State private var isTestingConnection = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            APIConfigurationView(
                settingsManager: settingsManager,
                apiService: apiService,
                showingFilePicker: $showingFilePicker,
                testResult: $testResult,
                isTestingConnection: $isTestingConnection
            )
            .tabItem {
                Label("API Configuration", systemImage: "key.fill")
            }
            .tag(0)
            
            APIInstructionsView()
                .tabItem {
                    Label("Instructions", systemImage: "info.circle")
                }
                .tag(1)
        }
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
