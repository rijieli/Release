//
//  ContentView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

struct ContentView: View {
    @StateObject private var apiService = AppStoreConnectService.shared
    @StateObject private var settingsManager = SettingsManager()
    @State private var selectedPlatform: Platform? = nil
    @State private var searchText = ""
    @State private var sortOrder = [KeyPathComparator(\AppInfo.name)]
    
    private var filteredApps: [AppInfo] {
        var apps = apiService.apps
        
        // Filter by platform
        if let selectedPlatform = selectedPlatform {
            apps = apps.filter { $0.platform == selectedPlatform }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            apps = apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleID.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return apps.sorted(using: sortOrder)
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with platform filter
            VStack(alignment: .leading, spacing: 16) {
                Text("Platforms")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                ForEach(Platform.allCases) { platform in
                    Button(action: {
                        selectedPlatform = selectedPlatform == platform ? nil : platform
                    }) {
                        HStack {
                            Image(systemName: platform.systemImage)
                                .foregroundStyle(selectedPlatform == platform ? .white : .primary)
                            Text(platform.rawValue)
                                .foregroundStyle(selectedPlatform == platform ? .white : .primary)
                            Spacer()
                            if selectedPlatform == platform {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPlatform == platform ? Color.accentColor : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                // Modern toolbar
                HStack {
                    // Search field with modern styling
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search apps...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                // Handle search submission if needed
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                await apiService.loadApps()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                        .disabled(apiService.isLoading)
                        
                        SettingsLink {
                            Image(systemName: "gear")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.regularMaterial)
                
                Divider()
                
                // Content area with modern states
                Group {
                    if !settingsManager.isConfigured {
                        ConfigurationRequiredView()
                    } else if apiService.isLoading {
                        LoadingView()
                    } else if apiService.apps.isEmpty {
                        EmptyStateView()
                    } else {
                        AppsTableView(apps: filteredApps, sortOrder: $sortOrder)
                    }
                }
            }
        }
        .navigationTitle("App Store Connect")
        .navigationSubtitle(settingsManager.isConfigured ? "\(apiService.apps.count) apps" : "Not configured")
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
        .onReceive(NotificationCenter.default.publisher(for: .refreshApps)) { _ in
            Task {
                await apiService.loadApps()
            }
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
}

// MARK: - Supporting Views

struct ConfigurationRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gear.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, isActive: true)
            
            VStack(spacing: 12) {
                Text("App Store Connect Not Configured")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Please configure your API credentials in Settings to view your apps.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            SettingsLink {
                Text("Open Settings")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

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

struct AppsTableView: View {
    let apps: [AppInfo]
    @Binding var sortOrder: [KeyPathComparator<AppInfo>]
    @StateObject private var detailManager = AppDetailManager.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Table(apps, sortOrder: $sortOrder) {
            TableColumn("App", value: \.name) { app in
                HStack(spacing: 12) {
                    Image(systemName: app.platform.systemImage)
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                        .symbolEffect(.bounce, value: app.status)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(app.bundleID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .width(min: 200, ideal: 300)
            
            TableColumn("Platform", value: \.platform) { app in
                HStack(spacing: 8) {
                    Image(systemName: app.platform.systemImage)
                    Text(app.platform.rawValue)
                }
                .font(.caption)
            }
            .width(120)
            
            TableColumn("Status", value: \.status) { app in
                HStack(spacing: 8) {
                    Image(systemName: app.status.systemImage)
                        .foregroundStyle(app.status.color)
                        .frame(width: 16, height: 16)
                        .symbolEffect(.pulse, isActive: app.status == .processingForAppStore)
                    
                    Text(app.status.description)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            .width(160)
            
            TableColumn("Version") { app in
                Text(app.version ?? "N/A")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(100)
            
            TableColumn("Actions") { app in
                Button("Details") {
                    detailManager.setSelectedApp(app)
                    openWindow(id: "app-detail")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .width(80)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    ContentView()
}
