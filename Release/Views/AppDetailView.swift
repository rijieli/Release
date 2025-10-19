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
    @State private var selectedPlatform: Platform? = nil
    @Environment(\.openURL) private var openURL

    private var activeDetail: AppDetail? {
        guard let detail = apiService.appDetail, detail.id == appInfo.id else { return nil }
        return detail
    }
    
    private var currentName: String { activeDetail?.name ?? appInfo.name }
    private var currentBundleID: String { activeDetail?.bundleID ?? appInfo.bundleID }
    private var currentPlatforms: [Platform] { activeDetail?.platforms ?? appInfo.platforms }
    private var activePlatform: Platform? {
        if let selectedPlatform, currentPlatforms.contains(selectedPlatform) {
            return selectedPlatform
        }
        return currentPlatforms.first
    }
    private var platformSummaryText: String? {
        guard !currentPlatforms.isEmpty else { return nil }
        if let activePlatform {
            return activePlatform.displayName
        }
        return currentPlatforms.map(\.displayName).joined(separator: ", ")
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
                            BasicInfoTab(appDetail: appDetail, selectedPlatform: activePlatform)
                        case .releaseNotes:
                            ReleaseNotesTab(appDetail: appDetail, selectedPlatform: activePlatform)
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
            syncSelectedPlatform()
        }
        .onChange(of: currentPlatforms) { _, _ in
            syncSelectedPlatform()
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
                    platform: activePlatform,
                    size: 80
                )
                .frame(width: 80, height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platforms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if currentPlatforms.count > 1, let firstPlatform = currentPlatforms.first {
                            Picker("Platform", selection: Binding(
                                get: { activePlatform ?? firstPlatform },
                                set: { selectedPlatform = $0 }
                            )) {
                                ForEach(currentPlatforms) { platform in
                                    Image(systemName: platform.systemImage)
                                        .tag(platform)
                                }
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        } else {
                            HStack(spacing: 6) {
                                ForEach(currentPlatforms) { platform in
                                    Image(systemName: platform.systemImage)
                                        .foregroundStyle(activePlatform == platform ? Color.accentColor : Color.secondary)
                                        .accessibilityLabel(platform.displayName)
                                }
                            }
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
    
    private func syncSelectedPlatform() {
        guard !currentPlatforms.isEmpty else {
            selectedPlatform = nil
            return
        }
        
        if let selectedPlatform, currentPlatforms.contains(selectedPlatform) {
            return
        }
        
        selectedPlatform = currentPlatforms.first
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
