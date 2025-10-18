//
//  AppIconView.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI

struct AppIconView: View {
    let iconURL: String?
    let platform: Platform
    let size: CGFloat
    
    init(iconURL: String?, platform: Platform, size: CGFloat = 40) {
        self.iconURL = iconURL
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
                            Image(systemName: platform.systemImage)
                                .font(.system(size: size * 0.4))
                                .foregroundStyle(.secondary)
                        }
                }
            } else {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(.regularMaterial)
                    .overlay {
                        Image(systemName: platform.systemImage)
                            .font(.system(size: size * 0.4))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}

#Preview {
    VStack(spacing: 20) {
        AppIconView(iconURL: nil, platform: .ios, size: 40)
        AppIconView(iconURL: "https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/8b/3e/0d/8b3e0d8b-3e0d-8b3e-0d8b-3e0d8b3e0d8b/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/512x512bb.jpg", platform: .ios, size: 60)
        AppIconView(iconURL: nil, platform: .macos, size: 40)
    }
    .padding()
}
