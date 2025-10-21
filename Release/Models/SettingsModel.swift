//
//  SettingsModel.swift
//  Release
//
//  Created by Roger on 2025/10/21.
//

import SwiftUI
import Combine

class SettingsModel: ObservableObject {
    static let shared = SettingsModel()

    @Published var debugTabVisible: Bool {
        didSet {
            UserDefaults.standard.set(debugTabVisible, forKey: "DebugTabVisible")
        }
    }

    @Published var debugUpdaterEnabled: Bool {
        didSet {
            UserDefaults.standard.set(debugUpdaterEnabled, forKey: "DebugUpdaterEnabled")
        }
    }

    @Published var ignoredUpdateVersion: String {
        didSet {
            UserDefaults.standard.set(ignoredUpdateVersion, forKey: "IgnoredUpdateVersion")
        }
    }

    @Published var step2TapCount: Int = 0 {
        didSet {
            if step2TapCount >= 5 && !debugTabVisible {
                debugTabVisible = true
            }
        }
    }

    private init() {
        self.debugTabVisible = UserDefaults.standard.bool(forKey: "DebugTabVisible")
        self.debugUpdaterEnabled = UserDefaults.standard.bool(forKey: "DebugUpdaterEnabled")
        self.ignoredUpdateVersion = UserDefaults.standard.string(forKey: "IgnoredUpdateVersion") ?? ""
    }

    func incrementStep2TapCount() {
        step2TapCount += 1
    }

    func resetStep2TapCount() {
        step2TapCount = 0
    }

    func ignoreUpdateVersion(_ version: String) {
        ignoredUpdateVersion = version
    }

    func shouldShowUpdateNotification(for latestVersion: String) -> Bool {
        return !ignoredUpdateVersion.isEmpty && ignoredUpdateVersion == latestVersion
    }
}