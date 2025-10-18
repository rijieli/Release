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
