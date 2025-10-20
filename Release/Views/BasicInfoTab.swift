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
    let selectedPlatform: Platform?
    
    private var platformSummary: String { appDetail.platform.displayName }
    
    private var lastModifiedText: String? {
        guard let lastModified = appDetail.lastModified else { return nil }
        return DateFormatter.detailed.string(from: lastModified)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summaryCard
                identifiersCard
            }
            .padding()
        }
    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(appDetail.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text(appDetail.bundleID)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Viewing Platform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(platformSummary)
                    .font(.headline)
                
                PlatformBadge(
                    platform: appDetail.platform,
                    isSelected: true
                )
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                StatusBadge(status: appDetail.status)
                
                HStack(spacing: 12) {
                    if let version = appDetail.version {
                        MetadataChip(
                            title: "Version",
                            value: version,
                            systemImage: "number.circle"
                        )
                    }
                    
                    if let language = appDetail.primaryLanguage {
                        MetadataChip(
                            title: "Primary Language",
                            value: language.uppercased(),
                            systemImage: "globe"
                        )
                    }
                }
                
                if let lastModifiedText {
                    Text("Last Modified \(lastModifiedText)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var identifiersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Identifiers")
                .font(.headline)
            
            VStack(spacing: 12) {
                InfoRow(label: "App Store ID", value: appDetail.id)
                InfoRow(label: "SKU", value: appDetail.sku ?? "N/A")
                InfoRow(label: "Primary Language", value: appDetail.primaryLanguage ?? "N/A")
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

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

struct StatusBadge: View {
    let status: AppStatus
    
    var body: some View {
        Label {
            Text(status.description)
                .font(.subheadline)
                .fontWeight(.semibold)
        } icon: {
            Image(systemName: status.systemImage)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(status.color.opacity(0.18))
        )
        .foregroundStyle(status.color)
    }
}

struct MetadataChip: View {
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.12))
        )
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
