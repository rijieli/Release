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
    @State private var selectedTab: DetailTab = .basicInfo
    @Environment(\.openURL) private var openURL

    private var activeDetail: AppDetail? {
        // Extract original app ID from platform-specific ID
        let originalAppID = extractOriginalAppID(from: appInfo.id)
        guard let detail = apiService.appDetail, detail.id == originalAppID else { return nil }
        return detail
    }

    private func extractOriginalAppID(from id: String) -> String {
        // If the ID contains a platform suffix, extract the original app ID
        if let dashIndex = id.lastIndex(of: "-") {
            return String(id.prefix(upTo: dashIndex))
        }
        return id
    }
    
    private var currentName: String { activeDetail?.name ?? appInfo.name }
    private var currentBundleID: String { activeDetail?.bundleID ?? appInfo.bundleID }
    private var currentPlatform: Platform? {
        appInfo.platform
    }
    private var platformSummaryText: String? {
        return currentPlatform?.displayName
    }
    private var currentStatus: AppStatus { activeDetail?.status ?? appInfo.status }
    private var currentAppID: String { activeDetail?.id ?? appInfo.id }
    
    private var appStoreURL: URL? {
        guard currentAppID.allSatisfy(\.isNumber) else { return nil }
        return URL(string: "https://apps.apple.com/us/app/id\(currentAppID)")
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
                            BasicInfoTab(appDetail: appDetail, selectedPlatform: currentPlatform)
                        case .releaseNotes:
                            ReleaseNotesTab(appDetail: appDetail, selectedPlatform: currentPlatform)
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
                let originalAppID = extractOriginalAppID(from: appInfo.id)
                await apiService.loadAppDetail(for: originalAppID, platform: appInfo.platform)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // App icon
                AppIconView(
                    appId: currentAppID,
                    bundleID: currentBundleID,
                    platform: currentPlatform,
                    size: 80
                )
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platform")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let currentPlatform = currentPlatform {
                            HStack(spacing: 8) {
                                Image(systemName: currentPlatform.systemImage)
                                    .foregroundStyle(Color.accentColor)
                                    .font(.system(size: 16))

                                Text(currentPlatform.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 6))
                        } else {
                            Text("Unknown Platform")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let platformSummaryText {
                        Text(platformSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(currentBundleID)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Text("App ID: \(currentAppID)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Image(systemName: currentStatus.systemImage)
                            .foregroundStyle(currentStatus.color)
                        Text(currentStatus.description)
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
            .maxWidth(alignment: .leading)
            .padding(16)
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(width: 200, alignment: .leading)
    }

// MARK: - Supporting Views

private enum DetailTab: Int, Identifiable {
    case basicInfo
    case releaseNotes

    var id: Int { rawValue }
}

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
}
