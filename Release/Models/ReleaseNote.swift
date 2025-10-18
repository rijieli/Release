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
        let localeIdentifier = self.locale
        let userLocale = Locale.current
        
        if let localized = userLocale.localizedString(forIdentifier: localeIdentifier) {
            return localized
        }
        
        let locale = Locale(identifier: localeIdentifier)
        
        if let languageCode = locale.language.languageCode?.identifier,
           let languageName = userLocale.localizedString(forLanguageCode: languageCode) ??
                              userLocale.localizedString(forIdentifier: languageCode) {
            
            var components: [String] = [languageName.capitalized(with: userLocale)]
            
            if let scriptCode = locale.language.script?.identifier {
                if let scriptName = userLocale.localizedString(forScriptCode: scriptCode) ??
                                    userLocale.localizedString(forIdentifier: "\(languageCode)-\(scriptCode)") {
                    components.append(scriptName.capitalized(with: userLocale))
                }
            }
            
            if let regionCode = locale.language.region?.identifier,
               let regionName = userLocale.localizedString(forRegionCode: regionCode) {
                components.append("(\(regionName))")
            }
            
            return components.joined(separator: " ")
        }
        
        return localeIdentifier
    }
}
