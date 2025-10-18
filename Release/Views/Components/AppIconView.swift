//
//  AppIconView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI

struct AppIconView: View {
    let appId: String
    let bundleID: String
    let platform: Platform
    let size: CGFloat
    
    @State private var iconURL: String?
    @State private var isLoadingIcon: Bool = false
    
    init(appId: String, bundleID: String, platform: Platform, size: CGFloat = 40) {
        self.appId = appId
        self.bundleID = bundleID
        self.platform = platform
        self.size = size
    }
    
    var body: some View {
        Group {
            if let iconURL = iconURL, let url = URL(string: iconURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .fill(.regularMaterial)
                        .overlay {
                            if isLoadingIcon {
                                ProgressView()
                                    .scaleEffect(0.5)
                            } else {
                                Image(systemName: platform.systemImage)
                                    .font(.system(size: size * 0.4))
                                    .foregroundStyle(.secondary)
                            }
                        }
                }
            } else {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(.regularMaterial)
                    .overlay {
                        if isLoadingIcon {
                            ProgressView()
                                .scaleEffect(0.5)
                        } else {
                            Image(systemName: platform.systemImage)
                                .font(.system(size: size * 0.4))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onAppear {
                        loadIconIfNeeded()
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
    
    private func loadIconIfNeeded() {
        guard iconURL == nil && !isLoadingIcon else { return }
        
        isLoadingIcon = true
        
        Task {
            if let fetchedIconURL = await iTunesService.shared.fetchAppIcon(for: bundleID) {
                await MainActor.run {
                    self.iconURL = fetchedIconURL
                    self.isLoadingIcon = false
                }
            } else {
                await MainActor.run {
                    self.isLoadingIcon = false
                }
            }
        }
    }
}
