//
//  SettingsManager.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation
import SwiftUI
import Combine

class SettingsManager: ObservableObject {
    @Published var config: AppStoreConnectConfig {
        didSet {
            if !config.isValid {
                isConfigured = false
            }
        }
    }
    @Published var isConfigured: Bool
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "AppStoreConnectConfig"
    
    init() {
        let loadedConfig = Self.loadConfig()
        self.config = loadedConfig
        self.isConfigured = loadedConfig.isValid
    }
    
    func saveConfig() {
        guard config.isValid else {
            isConfigured = false
            return
        }
        
        do {
            let data = try JSONEncoder().encode(config)
            userDefaults.set(data, forKey: configKey)
            isConfigured = config.isValid
        } catch {
            print("Failed to save config: \(error)")
        }
    }
    
    func clearConfig() {
        config = AppStoreConnectConfig()
        userDefaults.removeObject(forKey: configKey)
        isConfigured = false
    }
    
    private static func loadConfig() -> AppStoreConnectConfig {
        guard let data = UserDefaults.standard.data(forKey: "AppStoreConnectConfig"),
              let config = try? JSONDecoder().decode(AppStoreConnectConfig.self, from: data) else {
            return AppStoreConnectConfig()
        }
        return config
    }
}

extension SettingsManager {
    enum SettingsError: LocalizedError {
        case securityScopedAccessDenied
        case invalidFileEncoding
        case fileReadFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .securityScopedAccessDenied:
                return "Permission denied: Unable to access the selected file. Please try selecting the file again."
            case .invalidFileEncoding:
                return "Failed to read file content. Please ensure the file is a valid .p8 private key file."
            case .fileReadFailed(let error):
                return """
Failed to read private key file: \(error.localizedDescription)

Please ensure:
• The file is a valid .p8 private key file
• You have permission to read the file
• The file is not corrupted
"""
            }
        }
    }
    
    @MainActor
    func loadPrivateKey(from url: URL) throws {
        guard url.startAccessingSecurityScopedResource() else {
            throw SettingsError.securityScopedAccessDenied
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let data = try Data(contentsOf: url)
            guard let privateKeyString = String(data: data, encoding: .utf8) else {
                throw SettingsError.invalidFileEncoding
            }
            
            config.privateKey = privateKeyString
        } catch {
            throw SettingsError.fileReadFailed(error)
        }
    }
}
