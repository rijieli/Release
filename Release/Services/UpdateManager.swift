//
//  UpdateManager.swift
//  Release
//
//  Created by Roger on 2025/10/21.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class UpdateManager: ObservableObject {
    static let shared = UpdateManager()

    @Published var isCheckingForUpdates = false
    @Published var updateAvailable = false
    @Published var latestRelease: GitHubRelease?
    @Published var updateError: String?
    
    private var debugMode: Bool { SettingsModel.shared.debugUpdaterEnabled }

    private let owner = "rijieli"
    private let repo = "Release"
    private var ghToken: String? { AppConstants.githubToken }
    
    private init() {}

    func checkForUpdates() async {
        await MainActor.run {
            isCheckingForUpdates = true
            updateError = nil
        }

        do {
            let currentVersion = getCurrentVersion()
            let release = try await fetchLatestRelease()

            await MainActor.run {
                self.latestRelease = release

                // Check if there's a DMG asset available
                let hasDMGAsset = release.assets.contains { $0.name.lowercased().hasSuffix(".dmg") }

                if debugMode {
                    // Debug mode: show update available only if DMG asset exists
                    self.updateAvailable = hasDMGAsset
                } else {
                    // Normal mode: check version and DMG availability
                    self.updateAvailable = hasDMGAsset && isNewerVersion(release.tagName, currentVersion)
                }

                self.isCheckingForUpdates = false

                if debugMode {
                    print("Debug mode - Has DMG asset: \(hasDMGAsset), Update available: \(self.updateAvailable)")
                }
            }
        } catch {
            await MainActor.run {
                self.updateError = error.localizedDescription
                self.isCheckingForUpdates = false
            }
        }
    }

    func openDownloadURL() async {
        guard let release = latestRelease else {
            await MainActor.run {
                updateError = "No release information available"
            }
            return
        }

        // Find the first DMG asset
        guard let dmgAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }),
              let dmgURL = dmgAsset.downloadURL else {
            await MainActor.run {
                updateError = "No DMG file found in release assets"
            }
            return
        }

        await MainActor.run {
            updateError = nil // Clear previous error
        }

        do {
            await MainActor.run {
                NSWorkspace.shared.open(dmgURL)
            }

            if debugMode {
                print("Opened download URL in browser: \(dmgURL)")
            }
        } catch {
            await MainActor.run {
                self.updateError = "Failed to open download URL: \(error.localizedDescription)"
            }
        }
    }

    private func getCurrentVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "0.0.0"
    }

    private func fetchLatestRelease() async throws -> GitHubRelease {
        let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/releases/latest")!

        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        // Add GitHub token if available to avoid rate limiting
        if let token = ghToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            if debugMode {
                print("Using GitHub token for authentication")
            }
        } else if debugMode {
            print("No GitHub token found - may hit rate limits")
            print("To add token locally: Create Config.plist with GitHubToken key (add to .gitignore)")
            print("For CI/CD: Set GITHUB_TOKEN environment variable")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        #if DEBUG
        // print("=== GitHub API Response ===")
        // if let responseString = String(data: data, encoding: .utf8) {
        //     print("Response Body: \(responseString)")
        // }
        // print("=== End GitHub API Response ===")
        #endif

        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw UpdateError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    
    private func isNewerVersion(_ latest: String, _ current: String) -> Bool {
        let latestVersion = versionToNumber(latest.replacingOccurrences(of: "v", with: ""))
        let currentVersion = versionToNumber(current)
        return latestVersion > currentVersion
    }

    private func versionToNumber(_ version: String) -> Int {
        let components = version.split(separator: ".").compactMap { Int($0) }
        return components.reduce(0) { $0 * 100 + $1 }
    }
}

// MARK: - Models
struct GitHubRelease: Codable {
    let tagName: String
    let name: String
    let body: String
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case assets
    }
}

struct Asset: Codable {
    let name: String
    let browserDownloadURL: String

    enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }

    var downloadURL: URL? {
        return URL(string: browserDownloadURL)
    }
}

// MARK: - Errors
enum UpdateError: LocalizedError {
    case httpError(Int)
    case noDMGFound
    case failedToOpenURL

    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "GitHub API error (HTTP \(code))"
        case .noDMGFound:
            return "No DMG file found in release assets"
        case .failedToOpenURL:
            return "Failed to open download URL in browser"
        }
    }
}
