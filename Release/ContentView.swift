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
            apps = apps.filter { $0.platforms.contains(selectedPlatform) }
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Platforms")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                Button {
                    selectedPlatform = nil
                } label: {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(selectedPlatform == nil ? .white : .primary)
                        Text("All")
                            .foregroundStyle(selectedPlatform == nil ? .white : .primary)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedPlatform == nil ? Color.accentColor : Color.clear)
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                
                ForEach(Platform.allCases) { platform in
                    Button(action: {
                        selectedPlatform = selectedPlatform == platform ? nil : platform
                    }) {
                        HStack {
                            Image(systemName: platform.systemImage)
                                .foregroundStyle(selectedPlatform == platform ? .white : .primary)
                            Text(platform.displayName)
                                .foregroundStyle(selectedPlatform == platform ? .white : .primary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPlatform == platform ? Color.accentColor : Color.clear)
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                // Compact toolbar with inline search
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        
                        TextField("Search apps...", text: $searchText)
                            .textFieldStyle(.plain)
                            .onSubmit {
                                // Handle search submission if needed
                            }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    Task {
                        await apiService.loadApps()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(apiService.isLoading)
                
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
