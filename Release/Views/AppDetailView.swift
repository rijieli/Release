//
//  AppDetailView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import AppStoreConnect_Swift_SDK
import SwiftUI

struct AppDetailView: View {
    let appInfo: AppInfo
    @StateObject private var apiService = AppStoreConnectService.shared
    @State private var selectedTab: DetailTab = .releaseNotes
    @Environment(\.openURL) private var openURL

    private var displayedAppInfo: AppInfo {
        if let detail = apiService.appDetail, detail.id == appInfo.id {
            return detail.asAppInfo
        }
        return appInfo
    }

    private var appStoreURL: URL? {
        guard displayedAppInfo.id.allSatisfy(\.isNumber) else { return nil }
        return URL(string: "https://apps.apple.com/us/app/id\(displayedAppInfo.id)")
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent.navigationSplitViewColumnWidth(200)
        } detail: {
            VStack(spacing: 0) {
                // Content area
                Group {
                    if apiService.isLoadingDetail {
                        LoadingDetailView()
                    } else if let appDetail = apiService.appDetail {
                        switch selectedTab {
                        case .basicInfo:
                            BasicInfoTab(appDetail: appDetail)
                        case .releaseNotes:
                            ReleaseNotesTab(appDetail: appDetail)
                        }
                    } else {
                        EmptyDetailView()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Detail Tab", selection: $selectedTab) {
                        Text("Basic Info").tag(DetailTab.basicInfo)
                        Text("Release Notes").tag(DetailTab.releaseNotes)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
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

    var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // App icon
            AppIconView(
                appId: displayedAppInfo.id,
                bundleID: displayedAppInfo.bundleID,
                platform: displayedAppInfo.platform,
                size: 80
            )
            .frame(width: 80, height: 80)

            VStack(alignment: .leading, spacing: 8) {
                Text(displayedAppInfo.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text(displayedAppInfo.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Text("App ID: \(displayedAppInfo.id)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Image(systemName: displayedAppInfo.platform.systemImage)
                        .foregroundStyle(.blue)
                    Text(displayedAppInfo.platform.rawValue)
                        .font(.caption)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: displayedAppInfo.status.systemImage)
                        .foregroundStyle(displayedAppInfo.status.color)
                    Text(displayedAppInfo.status.description)
                        .font(.caption)
                }
                
                if let url = appStoreURL {
                    Button {
                        openURL(url)
                    } label: {
                        Label("View in App Store", systemImage: "link")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .frame(width: 200)
    }
}

private enum DetailTab: Int, Identifiable {
    case basicInfo
    case releaseNotes
    
    var id: Int { rawValue }
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
