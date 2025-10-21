//
//  ContentView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import AppStoreConnect_Swift_SDK
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var apiService = AppStoreConnectService.shared
    @EnvironmentObject private var settingsManager: SettingsManager
    @EnvironmentObject private var updateManager: UpdateManager
    @State private var selectedPlatform: Platform? = nil
    @State private var searchText = ""
    @State private var sortOrder = [KeyPathComparator(\AppInfo.name)]
    @State private var showingFilePicker = false
    @State private var testResult: String?
    @State private var isTestingConnection = false
    @State private var showingUpdateSheet = false

    private var filteredApps: [AppInfo] {
        var apps = apiService.apps

        // Filter by platform
        if let selectedPlatform = selectedPlatform {
            apps = apps.filter { $0.platform == selectedPlatform }
        }

        // Filter by search text
        if !searchText.isEmpty {
            apps = apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText)
                    || app.bundleID.localizedCaseInsensitiveContains(searchText)
            }
        }

        return apps.sorted(using: sortOrder)
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar with platform filter
            VStack(alignment: .leading, spacing: 8) {
                Text("Platforms")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Button {
                    selectedPlatform = nil
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(
                                selectedPlatform == nil ? .white : .primary
                            )
                        Text("All")
                            .foregroundStyle(
                                selectedPlatform == nil ? .white : .primary
                            )
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                selectedPlatform == nil
                                    ? Color.accentColor : Color.clear
                            )
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)

                ForEach(Platform.allCases) { platform in
                    Button(action: {
                        selectedPlatform =
                            selectedPlatform == platform ? nil : platform
                    }) {
                        HStack {
                            Image(systemName: platform.systemImage)
                                .foregroundStyle(
                                    selectedPlatform == platform
                                        ? .white : .primary
                                )
                            Text(platform.displayName)
                                .foregroundStyle(
                                    selectedPlatform == platform
                                        ? .white : .primary
                                )
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    selectedPlatform == platform
                                        ? Color.accentColor : Color.clear
                                )
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                UpdateNotificationView(updateManager: updateManager)
            }
            .padding()
            .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                // Compact toolbar with inline search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("Search apps...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            // Handle search submission if needed
                        }
                }
                .padding(16)
                .background {
                    Color.white
                }

                Divider()

                // Content area with modern states
                Group {
                    if !settingsManager.isConfigured {
                        APIConfigurationView(
                            settingsManager: settingsManager,
                            apiService: apiService,
                            showingFilePicker: $showingFilePicker,
                            testResult: $testResult,
                            isTestingConnection: $isTestingConnection
                        )
                    } else if apiService.isLoading {
                        VStack(spacing: 20) {
                            ProgressView(
                                value: apiService.initialLoadingProgress,
                                total: 1.0
                            )
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 300)
                            .padding(20)

                            Text("Loading apps for platforms...")
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            Text(
                                "\(Int(apiService.initialLoadingProgress * 100))% complete"
                            )
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if apiService.apps.isEmpty {
                        EmptyStateView()
                    } else {
                        AppsTableView(apps: filteredApps, sortOrder: $sortOrder)
                    }
                }
            }
        }
        .navigationTitle("App Store Connect")
        .navigationSubtitle(
            settingsManager.isConfigured
                ? "\(apiService.apps.count) apps" : "Not configured"
        )
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        await apiService.loadApps()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(!settingsManager.isConfigured || apiService.isLoading)

                SettingsLink {
                    Image(systemName: "gearshape")
                }
            }
        }
        .onAppear {
            if settingsManager.isConfigured {
                apiService.configure(
                    issuerID: settingsManager.config.issuerID,
                    privateKeyID: settingsManager.config.privateKeyID,
                    privateKey: settingsManager.config.privateKey
                )

                Task {
                    await apiService.loadApps()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshApps)) {
            _ in
            Task {
                await apiService.loadApps()
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data, .text],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("Error", isPresented: .constant(apiService.errorMessage != nil))
        {
            Button("OK") {
                apiService.errorMessage = nil
            }
        } message: {
            if let errorMessage = apiService.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingUpdateSheet) {
            UpdateAvailableSheet(updateManager: updateManager)
        }
        .onChange(of: updateManager.updateAvailable) { _, available in
            if available && !updateManager.isDownloading
                && updateManager.updateError == nil
            {
                showingUpdateSheet = true
            }
        }
        .onChange(of: updateManager.isCheckingForUpdates) { _, isChecking in
            if !isChecking && !updateManager.updateAvailable
                && updateManager.updateError == nil
            {
                // Show "no updates available" message
                let alert = NSAlert()
                alert.messageText = "Check for Updates"
                alert.informativeText = "You're using the latest version."
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
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
            apiService.errorMessage =
                "Failed to select file: \(error.localizedDescription)"
        }
    }
}
// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)

            Text("Loading apps...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Helpers

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "app.badge")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("No Apps Found")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("No apps were found in your App Store Connect account.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
