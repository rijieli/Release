//
//  AppsTableView.swift
//  Release
//
//  Created by Roger on 2025/10/18.
//  Copyright © 2025 Ideas Form. All rights reserved.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

struct AppsTableView: View {
    let apps: [AppInfo]
    @Binding var sortOrder: [KeyPathComparator<AppInfo>]
    @StateObject private var detailManager = AppDetailManager.shared
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Table(apps, sortOrder: $sortOrder) {
            TableColumn("App", value: \.name) { app in
                HStack(spacing: 12) {
                    AppIconView(
                        appId: app.id,
                        bundleID: app.bundleID,
                        platform: app.primaryPlatform,
                        size: 32
                    )
                    .symbolEffect(.bounce, value: app.status)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Text(app.bundleID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .width(min: 100, ideal: 150)

            TableColumn("Platform") { app in
                if app.platforms.isEmpty {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            ForEach(app.platforms) { platform in
                                Image(systemName: platform.systemImage)
                                    .accessibilityLabel(platform.displayName)
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    .font(.caption)
                }
            }
            .width(160)

            TableColumn("Status", value: \.status) { app in
                HStack(spacing: 8) {
                    Image(systemName: app.status.systemImage)
                        .foregroundStyle(app.status.color)
                        .frame(width: 16, height: 16)
                        .symbolEffect(.pulse, isActive: app.status == .processingForAppStore)

                    Text(app.status.description)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
            .width(160)

            TableColumn("Version") { app in
                Text(app.version ?? "N/A")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .width(100)

            TableColumn("Actions") { app in
                Button("Details") {
                    detailManager.setSelectedApp(app)
                    openWindow(id: "app-detail")
                }
                .buttonStyle(.bordered)
            }
            .width(80)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .scrollContentBackground(.hidden)
    }
}
