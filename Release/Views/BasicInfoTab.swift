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
                // App Icon Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Icon")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 16) {
                        AppIconView(iconURL: appDetail.iconURL, platform: appDetail.platform, size: 80)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(appDetail.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(appDetail.bundleID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if appDetail.iconURL == nil {
                                Text("Icon not available")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
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
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Status Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Status Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Image(systemName: appDetail.status.systemImage)
                            .foregroundStyle(appDetail.status.color)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appDetail.status.rawValue)
                                .font(.headline)
                            
                            Text(statusDescription(for: appDetail.status))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(appDetail.status.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                
                // Platform Information Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Platform Information")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Image(systemName: appDetail.platform.systemImage)
                            .foregroundStyle(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appDetail.platform.rawValue)
                                .font(.headline)
                            
                            Text(platformDescription(for: appDetail.platform))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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

#Preview {
    BasicInfoTab(appDetail: AppDetail(
        id: "123",
        name: "Sample App",
        bundleID: "com.example.app",
        platform: .ios,
        status: .readyForSale,
        version: "1.0.0",
        sku: "SAMPLE123",
        primaryLanguage: "en"
    ))
}
