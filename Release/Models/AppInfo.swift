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
    let platform: Platform
    let status: AppStatus
    let version: String?
    let lastModified: Date?

    init(
        id: String,
        name: String,
        bundleID: String,
        platform: Platform,
        status: AppStatus,
        version: String? = nil,
        lastModified: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.platform = platform
        self.status = status
        self.version = version
        self.lastModified = lastModified
    }
}

extension AppInfo {
    var platformDisplayText: String {
        platform.displayName
    }
}
