//
//  AppDetailView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

struct AppDetailView: View {
    let appInfo: AppInfo
    @StateObject private var apiService = AppStoreConnectService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationSplitView {
            // Sidebar with app info
            VStack(alignment: .leading, spacing: 16) {
                // App icon placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: appInfo.platform.systemImage)
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(appInfo.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text(appInfo.bundleID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Image(systemName: appInfo.platform.systemImage)
                            .foregroundStyle(.blue)
                        Text(appInfo.platform.rawValue)
                            .font(.caption)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: appInfo.status.systemImage)
                            .foregroundStyle(appInfo.status.color)
                        Text(appInfo.status.rawValue)
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
            .padding()
            .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Detail Tab", selection: $selectedTab) {
                    Text("Basic Info").tag(0)
                    Text("Release Notes").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Divider()
                
                // Content area
                Group {
                    if apiService.isLoadingDetail {
                        LoadingDetailView()
                    } else if let appDetail = apiService.appDetail {
                        switch selectedTab {
                        case 0:
                            BasicInfoTab(appDetail: appDetail)
                        case 1:
                            ReleaseNotesTab(appDetail: appDetail)
                        default:
                            BasicInfoTab(appDetail: appDetail)
                        }
                    } else {
                        EmptyDetailView()
                    }
                }
            }
        }
        .navigationTitle("App Details")
        .navigationSubtitle(appInfo.name)
        .onAppear {
            Task {
                await apiService.loadAppDetail(for: appInfo.id)
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

struct LoadingDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.accentColor)
            
            Text("Loading app details...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "info.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("No Details Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Unable to load detailed information for this app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AppDetailView(appInfo: AppInfo(
        id: "123",
        name: "Sample App",
        bundleID: "com.example.app",
        platform: .ios,
        status: .readyForSale,
        version: "1.0.0"
    ))
}
