//
//  ReleaseNotesTab.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

struct ReleaseNotesTab: View {
    let appDetail: AppDetail
    
    var body: some View {
        VStack(spacing: 0) {
            if appDetail.releaseNotes.isEmpty {
                EmptyReleaseNotesView()
            } else {
                // Release notes content - show all languages
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(appDetail.releaseNotes) { releaseNote in
                            ReleaseNoteCard(releaseNote: releaseNote)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct ReleaseNoteCard: View {
    let releaseNote: ReleaseNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Version header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Version \(releaseNote.version)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let releaseDate = releaseNote.releaseDate {
                        Text("Released \(DateFormatter.releaseDate.string(from: releaseDate))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Language indicator
                if releaseNote.localizedNotes.count > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                        Text("\(releaseNote.localizedNotes.count) languages")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            // All localized release notes
            if releaseNote.localizedNotes.isEmpty {
                Text("No release notes available.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(releaseNote.localizedNotes) { localizedNote in
                        LocalizedReleaseNoteView(localizedNote: localizedNote)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct LocalizedReleaseNoteView: View {
    let localizedNote: LocalizedReleaseNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Language header
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text(localizedNote.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(localizedNote.locale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
            }
            
            // Release notes content
            if !localizedNote.notes.isEmpty {
                Text(localizedNote.notes)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("No release notes available in this language.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

struct EmptyReleaseNotesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                Text("No Release Notes")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("No release notes are available for this app.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Extensions

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

extension DateFormatter {
    static let releaseDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

#Preview {
    ReleaseNotesTab(appDetail: AppDetail(
        id: "123",
        name: "Sample App",
        bundleID: "com.example.app",
        platform: .ios,
        status: .readyForSale,
        version: "1.0.0",
        releaseNotes: [
            ReleaseNote(
                id: "1",
                version: "1.0.0",
                localizedNotes: [
                    LocalizedReleaseNote(
                        id: "1",
                        locale: "en",
                        notes: "• Bug fixes and performance improvements\n• New user interface\n• Enhanced security features"
                    ),
                    LocalizedReleaseNote(
                        id: "2",
                        locale: "zh-Hans",
                        notes: "• 错误修复和性能改进\n• 新用户界面\n• 增强的安全功能"
                    )
                ]
            )
        ]
    ))
}
