//
//  BasicInfoTab.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

struct BasicInfoTab: View {
    let appDetail: AppDetail
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // App Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    InfoRow(label: "Name", value: appDetail.name)
                    InfoRow(label: "Bundle ID", value: appDetail.bundleID)
                    InfoRow(label: "SKU", value: appDetail.sku ?? "N/A")
                    InfoRow(label: "Platform", value: appDetail.platform.rawValue)
                    InfoRow(label: "Status", value: appDetail.status.rawValue)
                    InfoRow(label: "Version", value: appDetail.version ?? "N/A")
                    InfoRow(label: "Primary Language", value: appDetail.primaryLanguage ?? "N/A")
                    
                    if let lastModified = appDetail.lastModified {
                        InfoRow(label: "Last Modified", value: DateFormatter.detailed.string(from: lastModified))
                    }
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    private func statusDescription(for status: AppStatus) -> String {
        status.description
    }
    
    private func platformDescription(for platform: Platform) -> String {
        switch platform {
        case .ios:
            return "iOS - iPhone and iPad applications"
        case .macos:
            return "macOS - Mac applications"
        case .tvos:
            return "tvOS - Apple TV applications"
        case .watchos:
            return "watchOS - Apple Watch applications"
        case .visionos:
            return "visionOS - Apple Vision Pro applications"
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let detailed: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }()
}
