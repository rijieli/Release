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
    let platform: Platform
    let status: AppStatus
    let version: String?
    let lastModified: Date?
    let sku: String?
    let primaryLanguage: String?
    
    init(
        id: String,
        name: String,
        bundleID: String,
        platform: Platform,
        status: AppStatus,
        version: String? = nil,
        lastModified: Date? = nil,
        sku: String? = nil,
        primaryLanguage: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.platform = platform
        self.status = status
        self.version = version
        self.lastModified = lastModified
        self.sku = sku
        self.primaryLanguage = primaryLanguage
    }
    
    // Convert to AppInfo for UI components that need basic info
    var asAppInfo: AppInfo {
        AppInfo(
            id: id,
            name: name,
            bundleID: bundleID,
            platform: platform,
            status: status,
            version: version,
            lastModified: lastModified
        )
    }
}
