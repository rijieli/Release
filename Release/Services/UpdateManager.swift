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
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    
    fileprivate let debugMode = true

    private let owner = "rijieli"
    private let repo = "Release"
    private var ghToken: String? {
        // Try to load from local config file (not committed to git)
        if let token = loadTokenFromConfig() {
            return token
        }
        // Fallback to environment variable (for CI/CD)
        return ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
    }

    private func loadTokenFromConfig() -> String? {
        guard let configPath = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let configDict = NSDictionary(contentsOfFile: configPath),
              let token = configDict["GitHubToken"] as? String,
              !token.isEmpty else {
            return nil
        }
        return token
    }

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

    func downloadAndInstallUpdate() async {
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
            isDownloading = true
            downloadProgress = 0
            updateError = nil // Clear previous error
        }

        do {
            let tempDir = FileManager.default.temporaryDirectory
            let dmgtName = dmgURL.lastPathComponent
            let localDMGPath = tempDir.appendingPathComponent(dmgtName)

            // Clean up any existing download first
            if FileManager.default.fileExists(atPath: localDMGPath.path) {
                try? FileManager.default.removeItem(at: localDMGPath)
                if debugMode {
                    print("Cleaned up existing download: \(localDMGPath.path)")
                }
            }

            // Download DMG
            try await downloadFile(from: dmgURL, to: localDMGPath, progress: { progress in
                await MainActor.run {
                    self.downloadProgress = progress
                }
            })

            // Mount and install
            try await installDMG(at: localDMGPath)

            // Clean up
            try? FileManager.default.removeItem(at: localDMGPath)

            await MainActor.run {
                self.isDownloading = false
                // Restart app after successful update
                NSApplication.shared.terminate(nil)
            }

        } catch {
            await MainActor.run {
                self.updateError = "Update failed: \(error.localizedDescription)"
                self.isDownloading = false
            }
        }
    }

    func retryUpdate() async {
        await downloadAndInstallUpdate()
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

        let printRequest = {
            print("=== GitHub API Response ===")
            print("URL: \(url)")
            print("Status Code: \((response as? HTTPURLResponse)?.statusCode ?? -1)")

            if let httpResponse = response as? HTTPURLResponse {
                print("Headers: \(httpResponse.allHeaderFields)")
            }

            // Try to print response as string
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body: \(responseString)")
            } else {
                print("Response Body: [Unable to decode as UTF-8 string]")
            }
            print("=== End GitHub API Response ===")
        }
        
        // Debug logging
        if debugMode {
            printRequest()
        }

        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw UpdateError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(GitHubRelease.self, from: data)
    }

    private func downloadFile(from url: URL, to destination: URL, progress: @escaping (Double) async -> Void) async throws {
        print("Starting download from: \(url)")

        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        let expectedLength = response.expectedContentLength

        if debugMode {
            print("Expected file size: \(expectedLength) bytes")
            print("Downloaded size: \(data.count) bytes")
        }

        // For this simple implementation, we'll simulate progress
        // since URLSession.shared.data() doesn't provide progress tracking
        let totalBytes = Int64(data.count)

        if expectedLength > 0 {
            for i in 1...10 {
                let progressValue = Double(i) / 10.0
                await progress(progressValue)

                if debugMode {
                    print("Download progress: \(i * 10)%")
                }

                // Add a small delay to make progress visible
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }

        print("Download completed. Total size: \(data.count) bytes")
        try data.write(to: destination)
    }

    private func installDMG(at path: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["attach", path.path, "-nobrowse", "-quiet"]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.mountFailed
        }

        // Find mounted volume
        let volumes = try FileManager.default.contentsOfDirectory(atPath: "/Volumes")
        let appVolumes = volumes.filter { $0.contains("Release") }

        guard let volume = appVolumes.first else {
            throw UpdateError.volumeNotFound
        }

        let volumePath = "/Volumes/\(volume)"
        let appsInDMG = try FileManager.default.contentsOfDirectory(atPath: volumePath)
            .filter { $0.hasSuffix(".app") }

        guard let appName = appsInDMG.first else {
            throw UpdateError.appNotFound
        }

        let sourceApp = "\(volumePath)/\(appName)"
        let destinationAppURL = URL(fileURLWithPath: Bundle.main.bundlePath)
        let destinationParent = destinationAppURL.deletingLastPathComponent().path

        // Replace current app
        process.executableURL = URL(fileURLWithPath: "/bin/cp")
        process.arguments = ["-R", sourceApp, destinationParent]

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw UpdateError.copyFailed
        }

        // Unmount
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["detach", volumePath]

        try process.run()
        process.waitUntilExit()
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
    case mountFailed
    case volumeNotFound
    case appNotFound
    case copyFailed
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .mountFailed:
            return "Failed to mount DMG"
        case .volumeNotFound:
            return "Could not find mounted volume"
        case .appNotFound:
            return "No app found in DMG"
        case .copyFailed:
            return "Failed to copy app to Applications"
        case .httpError(let code):
            return "GitHub API error (HTTP \(code))"
        }
    }
}
