//
//  AppIconView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI
import AppKit

struct AppIconView: View {
    let appId: String
    let bundleID: String
    let platform: Platform
    let size: CGFloat
    
    private static let imageCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 500
        cache.totalCostLimit = 75 * 1024 * 1024 // ~75 MB
        return cache
    }()
    
    @State private var iconURL: String?
    @State private var iconImage: Image?
    @State private var isLoadingIcon: Bool = false
    
    init(appId: String, bundleID: String, platform: Platform, size: CGFloat = 40) {
        self.appId = appId
        self.bundleID = bundleID
        self.platform = platform
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(.regularMaterial)
            
            if let iconImage = iconImage {
                iconImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoadingIcon {
                ProgressView()
                    .scaleEffect(0.5)
            } else {
                Image(systemName: platform.systemImage)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
        .task {
            await loadIconIfNeeded()
        }
    }
    
    private func loadIconIfNeeded() async {
        let alreadyHandled = await MainActor.run { iconImage != nil || isLoadingIcon }
        if alreadyHandled {
            return
        }
        
        await MainActor.run {
            isLoadingIcon = true
        }
        
        defer {
            Task { @MainActor in
                isLoadingIcon = false
            }
        }
        
        let existingURL = await MainActor.run { iconURL }
        if let existingURL,
           let cached = AppIconView.imageCache.object(forKey: existingURL as NSString) {
            await MainActor.run {
                iconImage = Image(nsImage: cached)
            }
            return
        }
        
        let resolvedURL: String?
        if let existingURL {
            resolvedURL = existingURL
        } else {
            resolvedURL = await iTunesService.shared.fetchAppIcon(for: bundleID)
        }
        
        guard let finalURLString = resolvedURL,
              let url = URL(string: finalURLString) else {
            return
        }
        
        await MainActor.run {
            iconURL = finalURLString
        }
        
        if let cached = AppIconView.imageCache.object(forKey: finalURLString as NSString) {
            await MainActor.run {
                iconImage = Image(nsImage: cached)
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let nativeImage = NSImage(data: data) else { return }
            
            AppIconView.imageCache.setObject(nativeImage, forKey: finalURLString as NSString, cost: data.count)
            
            await MainActor.run {
                iconImage = Image(nsImage: nativeImage)
            }
        } catch {
            // Ignore network failures; placeholder will remain
        }
    }
}
