//
//  Platform+Extensions.swift
//  Release
//
//  Created by Roger on 2025/10/21.
//

import AppStoreConnect_Swift_SDK

extension Platform: Identifiable {
    public var id: String { rawValue }
    
    private static let preferredOrder: [Platform] = [.ios, .macOs, .tvOs, .visionOs]
    
    var displayOrder: Int {
        Self.preferredOrder.firstIndex(of: self) ?? Self.preferredOrder.count
    }
    
    var displayName: String {
        switch self {
        case .ios:
            return "iOS"
        case .macOs:
            return "macOS"
        case .tvOs:
            return "tvOS"
        case .visionOs:
            return "visionOS"
        }
    }
    
    var systemImage: String {
        switch self {
        case .ios:
            return "iphone"
        case .macOs:
            return "laptopcomputer"
        case .tvOs:
            return "tv"
        case .visionOs:
            return "visionpro"
        @unknown default:
            return "app.fill"
        }
    }
}

extension Array where Element == Platform {
    func sortedForDisplay() -> [Platform] {
        var seen = Set<Platform>()
        var unique: [Platform] = []
        
        for platform in self {
            if seen.insert(platform).inserted {
                unique.append(platform)
            }
        }
        
        return unique.sorted { lhs, rhs in
            lhs.displayOrder < rhs.displayOrder
        }
    }
}

extension Set where Element == Platform {
    func sortedForDisplay() -> [Platform] {
        Array(self).sortedForDisplay()
    }
}
