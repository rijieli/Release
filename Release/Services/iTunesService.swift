//
//  iTunesService.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import Foundation
import SwiftUI
import Combine

struct iTunesSearchResponse: Codable {
    let results: [iTunesApp]
}

struct iTunesApp: Codable {
    let bundleId: String
    let trackName: String
    let artworkUrl512: String?
    let artworkUrl100: String?
    let artworkUrl60: String?
    let artworkUrl30: String?
    
    enum CodingKeys: String, CodingKey {
        case bundleId
        case trackName
        case artworkUrl512
        case artworkUrl100
        case artworkUrl60
        case artworkUrl30
    }
}

class iTunesService: ObservableObject {
    static let shared = iTunesService()
    
    private let baseURL = "https://itunes.apple.com/lookup"
    private let cache = NSCache<NSString, NSString>()
    
    private init() {
        // Configure cache
        cache.countLimit = 1000
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }
    
    func fetchAppIcon(for bundleID: String) async -> String? {
        // Check cache first
        if let cachedIconURL = cache.object(forKey: bundleID as NSString) {
            return cachedIconURL as String
        }
        
        do {
            let url = URL(string: "\(baseURL)?bundleId=\(bundleID)")!
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let response = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)
            
            guard let app = response.results.first else {
                return nil
            }
            
            // Prefer higher resolution icons, fallback to lower ones
            let iconURL = app.artworkUrl512 ?? app.artworkUrl100 ?? app.artworkUrl60 ?? app.artworkUrl30
            
            // Cache the result
            if let iconURL = iconURL {
                cache.setObject(iconURL as NSString, forKey: bundleID as NSString)
            }
            
            return iconURL
            
        } catch {
            print("Failed to fetch app icon for \(bundleID): \(error)")
            return nil
        }
    }
    
    func fetchAppIcons(for bundleIDs: [String]) async -> [String: String] {
        var results: [String: String] = [:]
        
        // Process in batches to avoid overwhelming the API
        let batchSize = 10
        for i in stride(from: 0, to: bundleIDs.count, by: batchSize) {
            let endIndex = min(i + batchSize, bundleIDs.count)
            let batch = Array(bundleIDs[i..<endIndex])
            
            await withTaskGroup(of: (String, String?).self) { group in
                for bundleID in batch {
                    group.addTask {
                        let iconURL = await self.fetchAppIcon(for: bundleID)
                        return (bundleID, iconURL)
                    }
                }
                
                for await (bundleID, iconURL) in group {
                    if let iconURL = iconURL {
                        results[bundleID] = iconURL
                    }
                }
            }
        }
        
        return results
    }
    
    func clearCache() {
        cache.removeAllObjects()
    }
}
