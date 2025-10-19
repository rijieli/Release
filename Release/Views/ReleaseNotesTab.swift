//
//  ReleaseNotesTab.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import Foundation
import AppStoreConnect_Swift_SDK

struct ReleaseNotesTab: View {
    let appDetail: AppDetail
    let selectedPlatform: Platform?
    
    @StateObject private var apiService = AppStoreConnectService.shared
    
    @State private var activeReleaseNoteID: String?
    @State private var editorStates: [LocaleEditorState]
    @State private var templateText: String
    @State private var isFetchingPreviousVersion: Bool = false
    @State private var pendingUploadLocaleID: String?
    @State private var showUploadConfirmation: Bool = false
    @State private var showUploadAllConfirmation: Bool = false
    @State private var alertMessage: String?
    
    private var isEditable: Bool {
        appDetail.status == .prepareForSubmission
    }
    
    private var displayedReleaseNotes: [ReleaseNote] {
        ReleaseNotesTab.resolveDisplayedReleaseNotes(for: appDetail, selectedPlatform: selectedPlatform)
    }
    
    private var orderedReleaseNotes: [ReleaseNote] {
        guard let activeReleaseNoteID,
              let index = displayedReleaseNotes.firstIndex(where: { $0.id == activeReleaseNoteID }) else {
            return displayedReleaseNotes
        }
        
        if index == 0 { return displayedReleaseNotes }
        
        var reordered = displayedReleaseNotes
        let active = reordered.remove(at: index)
        reordered.insert(active, at: 0)
        return reordered
    }
    
    private var editableReleaseNote: ReleaseNote? {
        orderedReleaseNotes.first
    }
    
    private var previousReleaseNotes: [ReleaseNote] {
        Array(orderedReleaseNotes.dropFirst())
    }
    
    private var hasPendingChanges: Bool {
        editorStates.contains(where: { $0.hasChanges })
    }
    
    private var hasPreviousVersion: Bool {
        displayedReleaseNotes.count > 1
    }
    
    init(appDetail: AppDetail, selectedPlatform: Platform?) {
        self.appDetail = appDetail
        self.selectedPlatform = selectedPlatform
        
        let initialNotes = ReleaseNotesTab.resolveDisplayedReleaseNotes(for: appDetail, selectedPlatform: selectedPlatform)
        let initialNote = initialNotes.first
        
        _activeReleaseNoteID = State(initialValue: initialNote?.id)
        _editorStates = State(initialValue: initialNote?.localizedNotes.map { LocaleEditorState(note: $0) } ?? [])
        _templateText = State(initialValue: "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isEditable, let editableReleaseNote {
                editableContent(for: editableReleaseNote, previousNotes: previousReleaseNotes)
                    .controlSize(.large)
            } else if displayedReleaseNotes.isEmpty {
                EmptyReleaseNotesView()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(displayedReleaseNotes) { releaseNote in
                            ReleaseNoteCard(releaseNote: releaseNote, selectedPlatform: selectedPlatform)
                        }
                    }
                    .padding()
                }
            }
        }
        .onChange(of: appDetail.releaseNotes) { _, _ in
            syncActiveReleaseNote()
            rebuildEditorStates()
        }
        .onChange(of: selectedPlatform) { _ in
            syncActiveReleaseNote()
            rebuildEditorStates(resetTemplate: true)
        }
        .onChange(of: activeReleaseNoteID) { _, _ in
            rebuildEditorStates(resetTemplate: true)
        }
        .confirmationDialog("Confirm Upload", isPresented: $showUploadConfirmation, titleVisibility: .visible) {
            Button("Upload") {
                if let localeID = pendingUploadLocaleID {
                    Task {
                        await uploadLocale(withId: localeID)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                pendingUploadLocaleID = nil
            }
        } message: {
            Text("Are you sure you want to upload the selected release notes?")
        }
        .confirmationDialog("Confirm Upload All", isPresented: $showUploadAllConfirmation, titleVisibility: .visible) {
            Button("Upload All") {
                Task {
                    await uploadAll()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Upload all release notes to App Store Connect?")
        }
        .alert("Upload Error", isPresented: Binding(get: { alertMessage != nil }, set: { isPresented in
            if !isPresented { alertMessage = nil }
        })) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            if let alertMessage = alertMessage {
                Text(alertMessage)
            }
        }
    }
    
    @ViewBuilder
    private func editableContent(for releaseNote: ReleaseNote, previousNotes: [ReleaseNote]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                editableHeader(for: releaseNote)
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach($editorStates) { $state in
                        EditableLocalizedReleaseNoteView(
                            state: $state,
                            canEdit: isEditable,
                            resetAction: { reset(localeID: state.id) },
                            uploadAction: { prepareUpload(localeID: state.id) }
                        )
                    }
                }
                
                if !previousNotes.isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Previous Versions")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        ForEach(previousNotes) { previousNote in
                            ReleaseNoteCard(releaseNote: previousNote, selectedPlatform: selectedPlatform)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private func editableHeader(for releaseNote: ReleaseNote) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Version \(releaseNote.version)")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let releaseDate = releaseNote.releaseDate {
                    Text("Last updated \(DateFormatter.releaseDate.string(from: releaseDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let platform = releaseNote.platform {
                PlatformBadge(
                    platform: platform,
                    isSelected: selectedPlatform == platform
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Template")
                    .font(.headline)
                
                ReleaseEditor(
                    text: $templateText,
                    isEditable: isEditable,
                    minHeight: 120
                )
                
                HStack(spacing: 12) {
                    Button("Apply All") {
                        applyTemplateToAll()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(templateText.isEmpty)
                    
                    Button("Reset All") {
                        resetAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!hasPendingChanges)
                    
                    Button("Upload All") {
                        showUploadAllConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!hasPendingChanges)
                    
                    Button("Fetch Previous Versions") {
                        Task { await fetchPreviousVersionNotes() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isFetchingPreviousVersion || !hasPreviousVersion)
                    
                    Spacer()
                    
                    if isFetchingPreviousVersion {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
        }
    }
    
    private func applyTemplateToAll() {
        guard !templateText.isEmpty else { return }
        for index in editorStates.indices {
            if editorStates[index].text != templateText {
                editorStates[index].text = templateText
                editorStates[index].uploadStatus = .pendingChanges
            }
        }
    }
    
    private func resetAll() {
        for index in editorStates.indices {
            editorStates[index].text = editorStates[index].originalText
            editorStates[index].uploadStatus = .idle
        }
    }
    
    private func reset(localeID: String) {
        guard let index = editorStates.firstIndex(where: { $0.id == localeID }) else { return }
        editorStates[index].text = editorStates[index].originalText
        editorStates[index].uploadStatus = .idle
    }
    
    private func prepareUpload(localeID: String) {
        pendingUploadLocaleID = localeID
        showUploadConfirmation = true
    }
    
    private func uploadLocale(withId localeID: String) async {
        var textToUpload: String?
        
        await MainActor.run {
            guard let index = editorStates.firstIndex(where: { $0.id == localeID }),
                  editorStates[index].hasChanges else {
                pendingUploadLocaleID = nil
                return
            }
            
            editorStates[index].uploadStatus = .uploading
            textToUpload = editorStates[index].text
        }
        
        guard let payload = textToUpload else { return }
        
        do {
            let updatedNote = try await apiService.updateReleaseNotes(localizationId: localeID, whatsNew: payload)
            await MainActor.run {
                if let index = editorStates.firstIndex(where: { $0.id == localeID }) {
                    editorStates[index].text = updatedNote.notes
                    editorStates[index].originalText = updatedNote.notes
                    editorStates[index].uploadStatus = .success
                }
                alertMessage = nil
                pendingUploadLocaleID = nil
            }
        } catch {
            await MainActor.run {
                if let index = editorStates.firstIndex(where: { $0.id == localeID }) {
                    editorStates[index].uploadStatus = .failure(error.localizedDescription)
                }
                alertMessage = error.localizedDescription
                pendingUploadLocaleID = nil
            }
        }
    }
    
    private func uploadAll() async {
        let ids = await MainActor.run { editorStates.compactMap { $0.hasChanges ? $0.id : nil } }
        guard !ids.isEmpty else {
            await MainActor.run {
                showUploadAllConfirmation = false
            }
            return
        }
        
        for localeID in ids {
            await uploadLocale(withId: localeID)
        }
        await MainActor.run {
            showUploadAllConfirmation = false
        }
    }
    
    private func fetchPreviousVersionNotes() async {
        guard !isFetchingPreviousVersion else { return }
        let releaseNotes = currentReleaseNotes()
        guard releaseNotes.count > 1 else { return }
        
        await MainActor.run {
            isFetchingPreviousVersion = true
        }
        
        let previous = releaseNotes.dropFirst().first
        let previousNotesByLocale = previous.map { Dictionary(uniqueKeysWithValues: $0.localizedNotes.map { ($0.locale, $0.notes) }) } ?? [:]
        
        await MainActor.run {
            for index in editorStates.indices {
                if let previousNote = previousNotesByLocale[editorStates[index].locale], editorStates[index].text != previousNote {
                    editorStates[index].text = previousNote
                    editorStates[index].uploadStatus = .pendingChanges
                }
            }
            templateText = previous?.localizedNotes.first?.notes ?? ""
            isFetchingPreviousVersion = false
        }
    }
    
    private func syncActiveReleaseNote() {
        let notes = displayedReleaseNotes
        
        if notes.isEmpty {
            if activeReleaseNoteID != nil {
                activeReleaseNoteID = nil
            }
            return
        }
        
        if let activeReleaseNoteID,
           notes.contains(where: { $0.id == activeReleaseNoteID }) {
            return
        }
        
        activeReleaseNoteID = notes.first?.id
    }
    
    private func rebuildEditorStates(resetTemplate: Bool = false) {
        let existingStates = resetTemplate ? [] : editorStates
        
        guard let note = editableReleaseNote else {
            editorStates = []
            templateText = ""
            return
        }
        
        let mergedStates = note.localizedNotes.map { localization -> LocaleEditorState in
            if var existing = existingStates.first(where: { $0.id == localization.id }) {
                existing.originalText = localization.notes
                
                if existing.uploadStatus == .success {
                    existing.text = localization.notes
                    existing.uploadStatus = .idle
                } else if !existing.hasChanges {
                    existing.text = localization.notes
                }
                
                return existing
            } else {
                return LocaleEditorState(note: localization)
            }
        }
        
        editorStates = mergedStates
        
        if resetTemplate || mergedStates.allSatisfy({ !$0.hasChanges }) {
            templateText = ""
        }
    }
    
    private func currentReleaseNotes() -> [ReleaseNote] {
        let notes: [ReleaseNote]
        if let detail = apiService.appDetail, detail.id == appDetail.id {
            notes = ReleaseNotesTab.resolveDisplayedReleaseNotes(for: detail, selectedPlatform: selectedPlatform)
        } else {
            notes = displayedReleaseNotes
        }
        guard let activeReleaseNoteID,
              let index = notes.firstIndex(where: { $0.id == activeReleaseNoteID }) else {
            return notes
        }
        if index == 0 { return notes }
        var reordered = notes
        let active = reordered.remove(at: index)
        reordered.insert(active, at: 0)
        return reordered
    }
    
    private static func resolveDisplayedReleaseNotes(for appDetail: AppDetail, selectedPlatform: Platform?) -> [ReleaseNote] {
        let notes = appDetail.releaseNotes
        guard let selectedPlatform else { return notes }
        
        let filtered = notes.filter { note in
            guard let platform = note.platform else { return true }
            return platform == selectedPlatform
        }
        
        return filtered.isEmpty ? notes : filtered
    }
}

struct ReleaseNoteCard: View {
    let releaseNote: ReleaseNote
    let selectedPlatform: Platform?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
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
                
                VStack(alignment: .trailing, spacing: 8) {
                    if let platform = releaseNote.platform {
                        PlatformBadge(
                            platform: platform,
                            isSelected: selectedPlatform == platform
                        )
                    }
                    
                    if releaseNote.localizedNotes.count > 1 {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text("\(releaseNote.localizedNotes.count) languages")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            if releaseNote.localizedNotes.isEmpty {
                Text("No release notes available.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(releaseNote.localizedNotes) { localizedNote in
                        LocalizedReleaseNoteView(localizedNote: localizedNote)
                    }
                }
            }
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ReleaseEditor: View {
    @Binding var text: String
    var isEditable: Bool = true
    var minHeight: CGFloat = 68
    
    var body: some View {
        TextEditor(text: $text)
            .frame(minHeight: minHeight)
            .padding(8)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.secondary.opacity(0.3))
            )
            .scrollContentBackground(.hidden)
            .disabled(!isEditable)
            .opacity(isEditable ? 1 : 0.6)
    }
}

private struct EditableLocalizedReleaseNoteView: View {
    @Binding var state: LocaleEditorState
    
    let canEdit: Bool
    let resetAction: () -> Void
    let uploadAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "globe")
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text(state.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Text(state.locale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Reset") {
                        resetAction()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canEdit || !state.hasChanges || state.isUploading)
                    
                    Button("Upload") {
                        uploadAction()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(!canEdit || !state.hasChanges || state.isUploading)
                }
                
                StatusIndicator(status: state.uploadStatus)
            }
            
            ReleaseEditor(
                text: $state.text,
                isEditable: canEdit && !state.isUploading
            )
            .onChange(of: state.text) { _, newValue in
                guard canEdit, state.uploadStatus != .uploading else { return }
                if newValue == state.originalText {
                    state.uploadStatus = .idle
                } else {
                    state.uploadStatus = .pendingChanges
                }
            }
        }
    }
}

private struct StatusIndicator: View {
    let status: UploadState
    
    @ViewBuilder
    var body: some View {
        switch status {
        case .uploading:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 18, height: 18)
        case .idle:
            Image(systemName: "minus.circle")
                .foregroundStyle(.secondary)
                .frame(width: 18, height: 18)
        case .pendingChanges:
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.orange)
                .frame(width: 18, height: 18)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(width: 18, height: 18)
        case .failure:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .frame(width: 18, height: 18)
        }
    }
}

struct LocalizedReleaseNoteView: View {
    let localizedNote: LocalizedReleaseNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            if !localizedNote.notes.isEmpty {
                Text(localizedNote.notes)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("No release notes available in this language.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
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

// MARK: - Supporting Models

private struct LocaleEditorState: Identifiable {
    let id: String
    let locale: String
    let displayName: String
    var originalText: String
    var text: String
    var uploadStatus: UploadState = .idle
    
    var hasChanges: Bool {
        text != originalText
    }
    
    var isUploading: Bool {
        uploadStatus == .uploading
    }
    
    init(note: LocalizedReleaseNote) {
        self.id = note.id
        self.locale = note.locale
        self.displayName = note.displayName
        self.originalText = note.notes
        self.text = note.notes
    }
}

private enum UploadState: Equatable {
    case idle
    case pendingChanges
    case uploading
    case success
    case failure(String)
    
    var accessibilityDescription: String {
        switch self {
        case .idle:
            return "No changes"
        case .pendingChanges:
            return "Pending upload"
        case .uploading:
            return "Uploading"
        case .success:
            return "Upload successful"
        case .failure(let message):
            return "Upload failed: \(message)"
        }
    }
}
