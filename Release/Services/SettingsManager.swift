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
            isConfigured = config.isValid
        }
    }
    @Published var isConfigured: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let configKey = "AppStoreConnectConfig"
    
    init() {
        self.config = Self.loadConfig()
        self.isConfigured = config.isValid
    }
    
    func saveConfig() {
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
