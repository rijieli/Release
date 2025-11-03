//
//  AppStoreConnectService.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation
import AppStoreConnect_Swift_SDK
import Combine
import SwiftUI

class AppStoreConnectService: ObservableObject {
    static let shared = AppStoreConnectService()
    
    @Published var apps: [AppInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var appDetail: AppDetail?
    @Published var isLoadingDetail: Bool = false
    @Published var initialLoadingProgress: Double = 0.0
    @Published var isInitialLoadingComplete: Bool = false
    
    private var configuration: APIConfiguration?
    private var loadingBasicDetailAppIDs: Set<String> = []
    private var loadedBasicDetailAppIDs: Set<String> = []

    private let targetPlatforms: [Platform] = [.ios, .macOs, .tvOs, .visionOs]
    
    enum ServiceError: LocalizedError {
        case notConfigured
        case missingLocalization
        
        var errorDescription: String? {
            switch self {
            case .notConfigured:
                return "API not configured. Please check your settings."
            case .missingLocalization:
                return "Unable to find the targeted localization."
            }
        }
    }
    
    private init() {}
    
    func configure(issuerID: String, privateKeyID: String, privateKey: String) {
        do {
            // Try different approaches - the SDK might expect just the base64 content
            let privateKeyToUse: String
            
            if privateKey.contains("-----BEGIN PRIVATE KEY-----") {
                // Extract just the base64 content between headers
                let lines = privateKey.components(separatedBy: .newlines)
                    .filter { !$0.contains("-----BEGIN") && !$0.contains("-----END") }
                    .joined()
                privateKeyToUse = lines
            } else {
                privateKeyToUse = privateKey
            }
            
            // Try to create the configuration with the private key
            do {
                configuration = try APIConfiguration(
                    issuerID: issuerID,
                    privateKeyID: privateKeyID,
                    privateKey: privateKeyToUse
                )
            } catch {
                // If that fails, try with the original private key
                configuration = try APIConfiguration(
                    issuerID: issuerID,
                    privateKeyID: privateKeyID,
                    privateKey: privateKey
                )
            }
            
        } catch {
            errorMessage = "Failed to configure API: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func reset() {
        apps = []
        appDetail = nil
        errorMessage = nil
        isLoading = false
        isLoadingDetail = false
        initialLoadingProgress = 0.0
        isInitialLoadingComplete = false
    }
    
    private func formatPrivateKeyForSDK(_ privateKey: String) -> String {
        // The SDK is very particular about the format
        // Ensure proper line breaks and no extra whitespace
        
        let lines = privateKey.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Reconstruct with proper formatting
        var formatted = ""
        for (index, line) in lines.enumerated() {
            if index == 0 {
                formatted += line + "\n"
            } else if line.contains("-----END") {
                formatted += line
            } else {
                formatted += line + "\n"
            }
        }
        
        return formatted
    }
    
    private func formatPrivateKey(_ privateKey: String) -> String {
        // Remove any existing headers/footers and whitespace
        let cleaned = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END EC PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        // If it's already in the correct format, return as is
        if privateKey.contains("-----BEGIN") {
            return privateKey
        }
        
        // Format as proper PEM
        let header = "-----BEGIN PRIVATE KEY-----"
        let footer = "-----END PRIVATE KEY-----"
        
        // Split into 64-character lines
        let lines = stride(from: 0, to: cleaned.count, by: 64).map {
            let start = cleaned.index(cleaned.startIndex, offsetBy: $0)
            let end = cleaned.index(start, offsetBy: min(64, cleaned.count - $0))
            return String(cleaned[start..<end])
        }
        
        return ([header] + lines + [footer]).joined(separator: "\n")
    }
    
    func loadApps() async {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let configuration = configuration else {
            await MainActor.run {
                errorMessage = "API not configured. Please check your settings."
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
            initialLoadingProgress = 0.0
            isInitialLoadingComplete = false
            apps = []
        }

        do {
            let provider = APIProvider(configuration: configuration)
            var allAppInfos: [AppInfo] = []

            // Get all apps
            let appsRequest = APIEndpoint.v1.apps.get(parameters: .init(
                fieldsApps: [.name, .bundleID],
                limit: 200
            ))

            let appsResponse = try await provider.request(appsRequest)
            let totalApps = appsResponse.data.count
            var processedCount = 0

            // For each app, get all versions and create AppInfo for each platform that has versions
            let appInfos = try await withThrowingTaskGroup(of: [AppInfo].self) { group in
                var results: [AppInfo] = []

                for app in appsResponse.data {
                    group.addTask { [weak self] in
                        guard let self = self else { return [] }
                        return try await self.loadAppInfoForAllPlatforms(app: app, provider: provider)
                    }
                }

                for try await appInfos in group {
                    results.append(contentsOf: appInfos)
                    processedCount += 1
                    
                    // Update progress
                    let progress = Double(processedCount) / Double(totalApps)
                    await MainActor.run {
                        self.initialLoadingProgress = progress
                    }
                }

                return results
            }

            allAppInfos = appInfos

            await MainActor.run {
                self.apps = allAppInfos.sorted { $0.name < $1.name }
                self.isLoading = false
                self.isInitialLoadingComplete = true
                self.initialLoadingProgress = 1.0
            }

            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            log.debug("📱 All apps loaded in \(String(format: "%.2f", totalTime))s (\(allAppInfos.count) total rows)")

        } catch {
            let totalTime = CFAbsoluteTimeGetCurrent() - startTime
            log.error("❌ Failed to load apps after \(String(format: "%.2f", totalTime))s: \(error.localizedDescription)")

            await MainActor.run {
                self.errorMessage = "Failed to load apps: \(error.localizedDescription)"
                self.isLoading = false
                self.isInitialLoadingComplete = false
            }
        }
    }

    private func loadAppInfoForAllPlatforms(app: AppStoreConnect_Swift_SDK.App, provider: APIProvider) async throws -> [AppInfo] {
        // Get all app store versions for this app (across all platforms)
        let versionsRequest = APIEndpoint.v1.apps.id(app.id).appStoreVersions.get(parameters: .init(
            fieldsAppStoreVersions: [.versionString, .appStoreState, .platform],
            limit: 50
        ))

        let versionsResponse = try await provider.request(versionsRequest)
        let bundleID = app.attributes?.bundleID ?? ""
        
        // Group versions by platform
        var platformVersionsMap: [Platform: [AppStoreConnect_Swift_SDK.AppStoreVersion]] = [:]
        for version in versionsResponse.data {
            guard let platform = version.attributes?.platform else { continue }
            if platformVersionsMap[platform] == nil {
                platformVersionsMap[platform] = []
            }
            platformVersionsMap[platform]?.append(version)
        }
        
        // Create AppInfo for each platform that has versions
        var appInfos: [AppInfo] = []
        for (platform, versions) in platformVersionsMap {
            guard let latestVersion = versions.first else { continue }
            let status = determineStatusFromAppStoreState(latestVersion.attributes?.appStoreState)
            
            appInfos.append(AppInfo(
                id: "\(app.id)-\(platform.id)",
                name: app.attributes?.name ?? "Unknown",
                bundleID: bundleID,
                platform: platform,
                status: status,
                version: latestVersion.attributes?.versionString,
                lastModified: latestVersion.attributes?.createdDate
            ))
        }
        
        return appInfos
    }

    func testConnection() async -> Bool {
        guard let configuration = configuration else { 
            return false 
        }
        
        do {
            let provider = APIProvider(configuration: configuration)
            let request = APIEndpoint.v1.apps.get(parameters: .init(limit: 1))
            
            _ = try await provider.request(request)
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Connection test failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func determineStatusFromAppStoreState(_ appStoreState: AppStoreConnect_Swift_SDK.AppStoreVersionState?) -> AppStatus {
        guard let state = appStoreState else {
            return .prepareForSubmission
        }
        
        return state
    }
    
    private func determineStatus(from version: AppStoreConnect_Swift_SDK.App.Relationships.AppStoreVersions.Datum?) -> AppStatus {
        // This method is kept for backward compatibility but should not be used
        return .prepareForSubmission
    }
    
    
    // MARK: - App Detail Methods
    
    func loadAppDetails(for app: AppInfo) async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let shouldLoad = await MainActor.run { () -> Bool in
            if loadedBasicDetailAppIDs.contains(app.id) || loadingBasicDetailAppIDs.contains(app.id) {
                return false
            }
            loadingBasicDetailAppIDs.insert(app.id)
            return true
        }
        
        guard shouldLoad else { return }
        
        defer {
            Task { @MainActor in
                loadingBasicDetailAppIDs.remove(app.id)
            }
        }
        
        guard let configuration = configuration else { return }
        
        do {
            let provider = APIProvider(configuration: configuration)
            
            // Get app store versions for this specific app
            let versionsRequest = APIEndpoint.v1.apps.id(app.id).appStoreVersions.get(parameters: .init(
                fieldsAppStoreVersions: [.versionString, .appStoreState, .platform],
                limit: 200
            ))
            
            let versionsResponse = try await provider.request(versionsRequest)
            
            // Update the app with refreshed status information
            if let index = apps.firstIndex(where: { $0.id == app.id }) {
                let status: AppStatus
                let versionString: String?

                if let latestVersion = versionsResponse.data.first {
                    status = determineStatusFromAppStoreState(latestVersion.attributes?.appStoreState)
                    versionString = latestVersion.attributes?.versionString
                } else {
                    status = .prepareForSubmission
                    versionString = nil
                }

                let updatedApp = AppInfo(
                    id: app.id,
                    name: app.name,
                    bundleID: app.bundleID,
                    platform: app.platform,
                    status: status,
                    version: versionString,
                    lastModified: app.lastModified
                )
                
                await MainActor.run {
                    self.apps[index] = updatedApp
                    self.loadedBasicDetailAppIDs.insert(app.id)
                }
                
                let loadTime = CFAbsoluteTimeGetCurrent() - startTime
                log.debug("📊 App details loaded for \(app.name) in \(String(format: "%.2f", loadTime))s")
            }
        } catch {
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            log.warning("⚠️ Failed to load details for \(app.name) after \(String(format: "%.2f", loadTime))s")
        }
    }
    
    func loadAppDetail(for appId: String, platform: Platform) async {
        guard let configuration = configuration else {
            await MainActor.run {
                errorMessage = "API not configured. Please check your settings."
            }
            return
        }
        
        await MainActor.run {
            isLoadingDetail = true
            errorMessage = nil
        }
        
        do {
            let provider = APIProvider(configuration: configuration)
            
            // Get detailed app information
            let appRequest = APIEndpoint.v1.apps.id(appId).get(parameters: .init(
                fieldsApps: [.name, .bundleID, .sku, .primaryLocale],
                include: [.appStoreVersions]
            ))
            
            let appResponse = try await provider.request(appRequest)
            
            // Get app store versions with release notes
            let versionsRequest = APIEndpoint.v1.apps.id(appId).appStoreVersions.get(parameters: .init(
                fieldsAppStoreVersions: [.versionString, .appStoreState, .platform, .releaseType],
                limit: 10,
                include: [.appStoreVersionLocalizations],
            ))
            
            let versionsResponse = try await provider.request(versionsRequest)
            
            // Create AppDetail
            let app = appResponse.data
            
            let platforms = versionsResponse.data
                .compactMap { $0.attributes?.platform }
                .sortedForDisplay()
            let status: AppStatus
            
            if let latestVersion = versionsResponse.data.first {
                status = determineStatusFromAppStoreState(latestVersion.attributes?.appStoreState)
            } else {
                status = .prepareForSubmission
            }
            
            let appDetail = AppDetail(
                id: app.id,
                name: app.attributes?.name ?? "Unknown",
                bundleID: app.attributes?.bundleID ?? "",
                platform: platform,
                status: status,
                version: versionsResponse.data.first?.attributes?.versionString,
                sku: app.attributes?.sku,
                primaryLanguage: app.attributes?.primaryLocale
            )
            
            await MainActor.run {
                self.appDetail = appDetail
                self.isLoadingDetail = false
                
                // No need to update apps array since each AppInfo represents a single platform
                // The apps are already loaded with their specific platforms
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load app details: \(error.localizedDescription)"
                self.isLoadingDetail = false
            }
        }
    }
}

extension AppStoreConnectService {
    func updateReleaseNotes(localizationId: String, whatsNew: String) async throws -> LocalizedReleaseNote {
        guard let configuration = configuration else {
            throw ServiceError.notConfigured
        }
        
        let provider = APIProvider(configuration: configuration)
        let body = AppStoreVersionLocalizationUpdateRequest(
            data: .init(
                type: .appStoreVersionLocalizations,
                id: localizationId,
                attributes: .init(whatsNew: whatsNew)
            )
        )
        
        let response = try await provider.request(
            APIEndpoint.v1.appStoreVersionLocalizations
                .id(localizationId)
                .patch(body)
        )
        
        guard let attributes = response.data.attributes else {
            throw ServiceError.missingLocalization
        }
        
        let updatedNote = LocalizedReleaseNote(
            id: response.data.id,
            locale: attributes.locale ?? "en",
            notes: attributes.whatsNew ?? "",
            whatsNew: attributes.whatsNew
        )
        
  
        return updatedNote
    }

    func loadReleaseNotes(for appId: String, platform: Platform? = nil) async throws -> [ReleaseNote] {
        guard let configuration = configuration else {
            throw ServiceError.notConfigured
        }

        let provider = APIProvider(configuration: configuration)

        let versionsRequest = APIEndpoint.v1.apps.id(appId).appStoreVersions.get(parameters: .init(
            fieldsAppStoreVersions: [.versionString, .appStoreState, .platform, .releaseType],
            limit: 10,
            include: [.appStoreVersionLocalizations],
        ))

        let versionsResponse = try await provider.request(versionsRequest)

        var releaseNotes: [ReleaseNote] = []

        for version in versionsResponse.data {
            let releaseNotesRequest = APIEndpoint.v1.appStoreVersions.id(version.id).appStoreVersionLocalizations.get(parameters: .init(
                fieldsAppStoreVersionLocalizations: [.locale, .whatsNew]
            ))

            do {
                let releaseNotesResponse = try await provider.request(releaseNotesRequest)

                let localizedNotes = releaseNotesResponse.data.map { localization in
                    LocalizedReleaseNote(
                        id: localization.id,
                        locale: localization.attributes?.locale ?? "en",
                        notes: localization.attributes?.whatsNew ?? "",
                        whatsNew: localization.attributes?.whatsNew
                    )
                }

                if !localizedNotes.isEmpty {
                    let releaseNote = ReleaseNote(
                        id: version.id,
                        version: version.attributes?.versionString ?? "Unknown",
                        platform: version.attributes?.platform,
                        localizedNotes: localizedNotes,
                        releaseDate: version.attributes?.earliestReleaseDate ?? version.attributes?.createdDate
                    )
                    releaseNotes.append(releaseNote)
                }
            } catch {
                log.warning("⚠️ Failed to load release notes for version \(version.id): \(error.localizedDescription)")
            }
        }

        if let selectedPlatform = platform {
            let filtered = releaseNotes.filter { note in
                guard let notePlatform = note.platform else { return true }
                return notePlatform == selectedPlatform
            }
            return filtered.isEmpty ? releaseNotes : filtered
        }

        return releaseNotes
    }
}
