//
//  AppInfo.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation
import SwiftUI

struct AppInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String
    let platform: Platform
    let status: AppStatus
    let version: String?
    let lastModified: Date?
    
    init(id: String, name: String, bundleID: String, platform: Platform, status: AppStatus, version: String? = nil, lastModified: Date? = nil) {
        self.id = id
        self.name = name
        self.bundleID = bundleID
        self.platform = platform
        self.status = status
        self.version = version
        self.lastModified = lastModified
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

enum AppStatus: String, CaseIterable, Comparable {
    case readyForSale = "Ready for Sale"
    case pending = "Pending"
    case processing = "Processing"
    case rejected = "Rejected"
    case developerRejected = "Developer Rejected"
    case metadataRejected = "Metadata Rejected"
    case removedFromSale = "Removed from Sale"
    case invalidBinary = "Invalid Binary"
    
    var color: Color {
        switch self {
        case .readyForSale: return .green
        case .pending, .processing: return .orange
        case .rejected, .developerRejected, .metadataRejected, .invalidBinary: return .red
        case .removedFromSale: return .gray
        }
    }
    
    var systemImage: String {
        switch self {
        case .readyForSale: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .processing: return "gear.circle.fill"
        case .rejected, .developerRejected, .metadataRejected, .invalidBinary: return "xmark.circle.fill"
        case .removedFromSale: return "minus.circle.fill"
        }
    }
    
    static func < (lhs: AppStatus, rhs: AppStatus) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}
