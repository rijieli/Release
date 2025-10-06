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
    @Published var apps: [AppInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var configuration: APIConfiguration?
    
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
        guard let configuration = configuration else {
            await MainActor.run {
                errorMessage = "API not configured. Please check your settings."
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let provider = APIProvider(configuration: configuration)
            
            // First, get all apps
            let appsRequest = APIEndpoint.v1.apps.get(parameters: .init(
                fieldsApps: [.name, .bundleID],
                limit: 200
            ))
            
            let appsResponse = try await provider.request(appsRequest)
            
            // Then get app store versions for each app
            var versionMap: [String: String] = [:]
            
            for app in appsResponse.data {
                do {
                    let versionsRequest = APIEndpoint.v1.apps.id(app.id).appStoreVersions.get(parameters: .init(
                        fieldsAppStoreVersions: [.versionString, .appStoreState, .platform],
                        limit: 1
                    ))
                    
                    let versionsResponse = try await provider.request(versionsRequest)
                    
                    // Get the latest version (sorted by version string descending)
                    if let latestVersion = versionsResponse.data.first,
                       let versionString = latestVersion.attributes?.versionString {
                        versionMap[app.id] = versionString
                    }
                } catch {
                    // Silently continue if version fetch fails for an app
                }
            }
            
            let response = appsResponse
            
            let appInfos = response.data.map { app in
                let platform = determinePlatform(from: app.attributes?.bundleID ?? "")
                let status = determineStatus(from: app.relationships?.appStoreVersions?.data?.first)
                let version = versionMap[app.id]
                
                return AppInfo(
                    id: app.id,
                    name: app.attributes?.name ?? "Unknown",
                    bundleID: app.attributes?.bundleID ?? "",
                    platform: platform,
                    status: status,
                    version: version
                )
            }
            
            await MainActor.run {
                self.apps = appInfos
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load apps: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func testConnection() async -> Bool {
        guard let configuration = configuration else { 
            return false 
        }
        
        do {
            let provider = APIProvider(configuration: configuration)
            let request = APIEndpoint.v1.apps.get(parameters: .init(limit: 1))
            
            let response = try await provider.request(request)
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Connection test failed: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    private func determinePlatform(from bundleID: String) -> Platform {
        // Simple heuristic based on bundle ID patterns
        if bundleID.contains("watch") {
            return .watchos
        } else if bundleID.contains("tv") {
            return .tvos
        } else if bundleID.contains("mac") || bundleID.hasSuffix(".mac") {
            return .macos
        } else {
            return .ios
        }
    }
    
    private func determineStatus(from version: AppStoreConnect_Swift_SDK.App.Relationships.AppStoreVersions.Datum?) -> AppStatus {
        // This would need to be expanded based on actual API response
        return .readyForSale
    }
}
