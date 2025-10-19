//
//  AppDetail.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import AppStoreConnect_Swift_SDK
import Foundation

struct AppDetail: Identifiable {
    let id: String
    let name: String
    let bundleID: String
    let platforms: [Platform]
    let status: AppStatus
    let version: String?
    let lastModified: Date?
    let sku: String?
    let primaryLanguage: String?
    let releaseNotes: [ReleaseNote]
    
    init(
        id: String,
        name: String,
        bundleID: String,
        platforms: [Platform] = [],
        status: AppStatus,
        version: String? = nil,
        lastModified: Date? = nil,
        sku: String? = nil,
        primaryLanguage: String? = nil,
        releaseNotes: [ReleaseNote] = []
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.platforms = platforms.sortedForDisplay()
        self.status = status
        self.version = version
        self.lastModified = lastModified
        self.sku = sku
        self.primaryLanguage = primaryLanguage
        self.releaseNotes = releaseNotes
    }
    
    // Convert to AppInfo for UI components that need basic info
    var asAppInfo: AppInfo {
        AppInfo(
            id: id,
            name: name,
            bundleID: bundleID,
            platforms: platforms,
            status: status,
            version: version,
            lastModified: lastModified
        )
    }
}

extension AppDetail {
    var primaryPlatform: Platform? {
        platforms.first
    }
    
    var platformsDisplayText: String? {
        guard !platforms.isEmpty else { return nil }
        return platforms.map(\.displayName).joined(separator: ", ")
    }
}
