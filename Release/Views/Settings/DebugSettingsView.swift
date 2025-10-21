//
//  DebugSettingsView.swift
//  Release
//
//  Created by Roger on 2025/10/21.
//

import SwiftUI

struct DebugSettingsView: View {
    @StateObject private var settingsModel = SettingsModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $settingsModel.debugUpdaterEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Debug Updater")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(
                            "Enable debug mode for the auto-updater with additional logging and testing features"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .maxWidth(alignment: .leading)
                }
                .toggleStyle(.switch)
            }
            .padding(16)
        }
        .maxFrame()
    }
}
