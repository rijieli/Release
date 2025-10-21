//
//  UpdateNotificationView.swift
//  Release
//
//  Created by Roger on 2025/10/21.
//

import SwiftUI

struct UpdateNotificationView: View {
    @ObservedObject var updateManager: UpdateManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack {
            if updateManager.updateAvailable && !updateManager.isDownloading {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.blue)

                    Text("New version \(updateManager.latestRelease?.tagName.replacingOccurrences(of: "v", with: "") ?? "") available")
                        .font(.caption)

                    Spacer()

                    Button("Update") {
                        Task {
                            await updateManager.downloadAndInstallUpdate()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Ignore") {
                        // Dismiss notification by setting updateAvailable to false
                        // User can still check manually later
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            } else if updateManager.isDownloading {
                VStack {
                    Text("Downloading update...")
                        .font(.caption)

                    ProgressView(value: updateManager.downloadProgress)
                        .controlSize(.small)
                }
            } else if let error = updateManager.updateError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("Update failed: \(error)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Retry") {
                        Task {
                            await updateManager.retryUpdate()
                        }
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            Capsule().fill(Color(nsColor: .controlBackgroundColor))
        }
    }
}

struct UpdateAvailableSheet: View {
    @ObservedObject var updateManager: UpdateManager
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
                if updateManager.isDownloading {
                    ProgressView()
                        .controlSize(.small)

                    Text("Downloading...")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if updateManager.downloadProgress > 0 {
                        Text("\(Int(updateManager.downloadProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Update Now") {
                        Task {
                            await updateManager.downloadAndInstallUpdate()
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Later") {
                        dismiss()
                    }
                    .keyboardShortcut(.escape)
                }
            }
            .controlSize(.large)
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }
}
