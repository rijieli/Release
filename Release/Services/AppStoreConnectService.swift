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
            // Log the configuration details for debugging
            print("🔧 Configuring App Store Connect API:")
            print("   Issuer ID: \(issuerID)")
            print("   Private Key ID: \(privateKeyID)")
            print("   Private Key Length: \(privateKey.count) characters")
            print("   Private Key Preview: \(String(privateKey.prefix(50)))...")
            
            // Try different approaches - the SDK might expect just the base64 content
            let privateKeyToUse: String
            
            if privateKey.contains("-----BEGIN PRIVATE KEY-----") {
                // Extract just the base64 content between headers
                let lines = privateKey.components(separatedBy: .newlines)
                    .filter { !$0.contains("-----BEGIN") && !$0.contains("-----END") }
                    .joined()
                privateKeyToUse = lines
                print("   Using raw base64 content without PEM headers")
            } else {
                privateKeyToUse = privateKey
                print("   Using private key as-is")
            }
            
            print("   Final Private Key Length: \(privateKeyToUse.count) characters")
            print("   Final Private Key Preview: \(String(privateKeyToUse.prefix(50)))...")
            
            // Try to create the configuration with the private key
            do {
                configuration = try APIConfiguration(
                    issuerID: issuerID,
                    privateKeyID: privateKeyID,
                    privateKey: privateKeyToUse
                )
            } catch {
                // If that fails, try with the original private key
                print("   First attempt failed, trying with original private key...")
                configuration = try APIConfiguration(
                    issuerID: issuerID,
                    privateKeyID: privateKeyID,
                    privateKey: privateKey
                )
            }
            
            print("✅ API Configuration successful!")
            
        } catch {
            print("❌ API Configuration failed:")
            print("   Error: \(error)")
            print("   Error Type: \(type(of: error))")
            print("   Localized Description: \(error.localizedDescription)")
            
            // Provide more detailed error information
            if let jwtError = error as? AppStoreConnect_Swift_SDK.JWT.Error {
                print("   JWT Error Details: \(jwtError)")
            }
            
            errorMessage = "Failed to configure API: \(error.localizedDescription)\n\nDebug Info:\n• Issuer ID: \(issuerID)\n• Key ID: \(privateKeyID)\n• Private Key Length: \(privateKey.count) chars\n• Error Type: \(type(of: error))\n\nThis might be a known issue with the App Store Connect Swift SDK. Try:\n• Using a different API key\n• Checking if the key has proper permissions\n• Verifying the key hasn't expired"
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
            let request = APIEndpoint.v1.apps.get(parameters: .init(
                limit: 200
            ))
            
            let response = try await provider.request(request)
            
            let appInfos = response.data.map { app in
                let platform = determinePlatform(from: app.attributes?.bundleID ?? "")
                let status = determineStatus(from: app.relationships?.appStoreVersions?.data?.first)
                
                return AppInfo(
                    id: app.id,
                    name: app.attributes?.name ?? "Unknown",
                    bundleID: app.attributes?.bundleID ?? "",
                    platform: platform,
                    status: status
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
            print("❌ No configuration available for connection test")
            return false 
        }
        
        print("🧪 Testing App Store Connect API connection...")
        
        do {
            let provider = APIProvider(configuration: configuration)
            let request = APIEndpoint.v1.apps.get(parameters: .init(limit: 1))
            
            print("   Making API request...")
            let response = try await provider.request(request)
            print("✅ Connection test successful! Found \(response.data.count) apps")
            
            return true
        } catch {
            print("❌ Connection test failed:")
            print("   Error: \(error)")
            print("   Error Type: \(type(of: error))")
            print("   Localized Description: \(error.localizedDescription)")
            
            await MainActor.run {
                self.errorMessage = "Connection test failed: \(error.localizedDescription)\n\nDebug Info:\n• Error Type: \(type(of: error))\n• Full Error: \(error)"
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
