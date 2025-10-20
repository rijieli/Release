//
//  PlatformBadge.swift
//  Release
//
//  Created by Roger on 2025/10/20.
//  Copyright © 2025 Ideas Form. All rights reserved.
//

import AppStoreConnect_Swift_SDK
import SwiftUI

struct PlatformBadge: View {
    let platform: Platform
    let isSelected: Bool

    var body: some View {
        Label {
            Text(platform.displayName)
                .font(.caption)
                .fontWeight(.medium)
        } icon: {
            Image(systemName: platform.systemImage)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
        )
        .foregroundStyle(isSelected ? Color.accentColor : .primary)
    }
}
