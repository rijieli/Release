//
//  SettingsView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @StateObject private var apiService = AppStoreConnectService.shared
    @StateObject private var settingsModel = SettingsModel.shared
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

            if settingsModel.debugTabVisible {
                DebugSettingsView()
                    .tabItem {
                        Label("Debug", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(2)
            }
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
                try settingsManager.loadPrivateKey(from: url)
            } catch {
                if let settingsError = error as? SettingsManager.SettingsError {
                    apiService.errorMessage = settingsError.errorDescription
                } else {
                    apiService.errorMessage = error.localizedDescription
                }
            }
            
        case .failure(let error):
            apiService.errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
}
