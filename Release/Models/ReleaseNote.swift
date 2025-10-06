//
//  ReleaseNote.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation

struct ReleaseNote: Identifiable, Hashable {
    let id: String
    let version: String
    let localizedNotes: [LocalizedReleaseNote]
    let releaseDate: Date?
    
    init(id: String, version: String, localizedNotes: [LocalizedReleaseNote], releaseDate: Date? = nil) {
        self.id = id
        self.version = version
        self.localizedNotes = localizedNotes
        self.releaseDate = releaseDate
    }
}

struct LocalizedReleaseNote: Identifiable, Hashable {
    let id: String
    let locale: String
    let notes: String
    let whatsNew: String?
    
    init(id: String, locale: String, notes: String, whatsNew: String? = nil) {
        self.id = id
        self.locale = locale
        self.notes = notes
        self.whatsNew = whatsNew
    }
    
    var displayName: String {
        let locale = Locale(identifier: self.locale)
        return locale.localizedString(forLanguageCode: locale.languageCode ?? "en") ?? self.locale
    }
}
