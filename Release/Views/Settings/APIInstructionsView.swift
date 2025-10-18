//
//  APIInstructionsView.swift
//  Release
//
//  Created by Roger on 2025/10/18.
//  Copyright © 2025 Ideas Form. All rights reserved.
//

import SwiftUI


struct APIInstructionsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Follow these steps to configure your App Store Connect API access.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    InstructionStep(
                        number: 1,
                        title: "Access App Store Connect",
                        description: "Go to App Store Connect → Users and Access → Keys",
                        icon: "person.badge.key"
                    )
                    
                    InstructionStep(
                        number: 2,
                        title: "Generate API Key",
                        description: "Click the '+' button to generate a new API key",
                        icon: "plus.circle"
                    )
                    
                    InstructionStep(
                        number: 3,
                        title: "Download Private Key",
                        description: "Download the private key file (.p8) to your computer",
                        icon: "arrow.down.circle"
                    )
                    
                    InstructionStep(
                        number: 4,
                        title: "Enter Credentials",
                        description: "Copy the Issuer ID and Key ID from the API key details",
                        icon: "doc.on.doc"
                    )
                    
                    InstructionStep(
                        number: 5,
                        title: "Upload Private Key",
                        description: "Use the 'Choose Private Key File' button to upload your .p8 file",
                        icon: "folder"
                    )
                    
                    InstructionStep(
                        number: 6,
                        title: "Test & Save",
                        description: "Test the connection and save your configuration",
                        icon: "checkmark.circle"
                    )
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
                
                // Additional Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Important Notes")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .frame(width: 16)
                            
                            Text("Keep your private key file secure and never share it")
                                .font(.caption)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                                .frame(width: 16)
                            
                            Text("API keys have expiration dates - you'll need to regenerate them periodically")
                                .font(.caption)
                        }
                        
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.green)
                                .frame(width: 16)
                            
                            Text("Your credentials are stored securely on your device")
                                .font(.caption)
                        }
                    }
                    .maxWidth(alignment: .leading)
                }
                .padding()
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
        }
        .maxFrame()
    }
}

fileprivate struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 16)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .maxWidth(alignment: .leading)
    }
}
