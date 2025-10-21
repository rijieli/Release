//
//  UpdateNotificationView.swift
//  Release
//
//  Created by Roger on 2025/10/21.
//

import SwiftUI

struct UpdateNotificationView: View {
    @ObservedObject var updateManager: UpdateManager
    @StateObject private var settingsModel = SettingsModel.shared
    @Environment(\.openWindow) private var openWindow

    var shouldShowNotification: Bool {
        guard let latestVersion = updateManager.latestRelease?.tagName else { return false }
        return updateManager.updateAvailable
            && !settingsModel.shouldShowUpdateNotification(for: latestVersion)
    }

    var body: some View {
        if shouldShowNotification {
            bannerView
        }
    }

    var bannerView: some View {
        HStack {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(.blue)

            Text(
                "Version \(updateManager.latestRelease?.tagName.replacingOccurrences(of: "v", with: "") ?? "") available"
            )
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .font(.caption)

            Spacer()

            Button("Download") {
                Task {
                    await updateManager.openDownloadURL()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button {
                // Ignore this version by adding it to ignored versions
                if let latestVersion = updateManager.latestRelease?.tagName {
                    settingsModel.ignoreUpdateVersion(latestVersion)
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 4)
        }
    }
}

struct UpdateAvailableSheet: View {
    @ObservedObject var updateManager: UpdateManager
    @StateObject private var settingsModel = SettingsModel.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Update Available")
                .font(.title2)
                .fontWeight(.semibold)

            if let release = updateManager.latestRelease {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Version:")
                            .fontWeight(.medium)
                        Text(release.tagName.replacingOccurrences(of: "v", with: ""))
                        Spacer()
                    }

                    if !release.body.isEmpty {
                        Text("Release Notes:")
                            .fontWeight(.medium)

                        ScrollView {
                            Text(release.body)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }

            HStack {
                Button("Download in Browser") {
                    Task {
                        await updateManager.openDownloadURL()
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Ignore This Version") {
                    if let latestVersion = updateManager.latestRelease?.tagName {
                        settingsModel.ignoreUpdateVersion(latestVersion)
                    }
                    dismiss()
                }

                Button("Later") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
            }
            .controlSize(.large)
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }
}
