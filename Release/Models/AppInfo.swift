//
//  AppInfo.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation
import AppStoreConnect_Swift_SDK
import SwiftUI

struct AppInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String
    let platforms: [Platform]
    let status: AppStatus
    let version: String?
    let lastModified: Date?
    
    init(
        id: String,
        name: String,
        bundleID: String,
        platforms: [Platform] = [],
        status: AppStatus,
        version: String? = nil,
        lastModified: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.platforms = platforms.sortedForDisplay()
        self.status = status
        self.version = version
        self.lastModified = lastModified
    }
}

extension AppInfo {
    var primaryPlatform: Platform? {
        platforms.first
    }
    
    var platformsDisplayText: String? {
        guard !platforms.isEmpty else { return nil }
        return platforms.map(\.displayName).joined(separator: ", ")
    }
}
