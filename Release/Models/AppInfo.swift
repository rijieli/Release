//
//  AppInfo.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation
import SwiftUI
import AppStoreConnect_Swift_SDK

struct AppInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String
    let platform: Platform
    let status: AppStatus
    let version: String?
    let lastModified: Date?
    let iconURL: String?
    
    init(id: String, name: String, bundleID: String, platform: Platform, status: AppStatus, version: String? = nil, lastModified: Date? = nil, iconURL: String? = nil) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.platform = platform
        self.status = status
        self.version = version
        self.lastModified = lastModified
        self.iconURL = iconURL
    }
}

enum Platform: String, CaseIterable, Identifiable, Comparable {
    case ios = "iOS"
    case macos = "macOS"
    case tvos = "tvOS"
    case watchos = "watchOS"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .ios: return "iphone"
        case .macos: return "laptopcomputer"
        case .tvos: return "tv"
        case .watchos: return "applewatch"
        }
    }
    
    static func < (lhs: Platform, rhs: Platform) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
