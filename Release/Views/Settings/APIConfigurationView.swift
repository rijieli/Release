//
//  APIConfigurationView.swift
//  Release
//
//  Created by Roger on 2025/10/18.
//  Copyright © 2025 Ideas Form. All rights reserved.
//

import SwiftUI
import AppStoreConnect_Swift_SDK

struct APIConfigurationView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var apiService: AppStoreConnectService
    @Binding var showingFilePicker: Bool
    @Binding var testResult: String?
    @Binding var isTestingConnection: Bool
    @State private var showingClearConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            settingsContent
            HStack(spacing: 12) {
                Button("Test Connection") {
                    testConnection()
                }
                .buttonStyle(.bordered)
                .disabled(!settingsManager.isConfigured || isTestingConnection)

                if isTestingConnection {
                    ProgressView()
                        .scaleEffect(0.8)
                }

                Spacer()

                Button("Save Configuration") {
                    settingsManager.saveConfig()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!settingsManager.isConfigured)

                Button("Clear", role: .destructive) {
                    showingClearConfirmation = true
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .frame(height: 42)
            .padding(.horizontal, 12)
        }
        .alert("Clear Configuration?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear Anyway", role: .destructive) {
                settingsManager.clearConfig()
                testResult = nil
            }
        } message: {
            Text("Double-check your credentials before clearing. This action removes the saved API settings.")
        }
    }
    
    var settingsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                Text("Configure your App Store Connect API credentials to manage your apps.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                // Configuration Form
                VStack(spacing: 20) {
                    // Issuer ID
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Issuer ID", systemImage: "person.badge.key")
                            .font(.headline)

                        TextField("Enter your Issuer ID", text: $settingsManager.config.issuerID)
                            .textFieldStyle(.roundedBorder)
                            .help("Your App Store Connect Issuer ID")
                    }

                    // Private Key ID
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Private Key ID", systemImage: "key")
                            .font(.headline)

                        TextField(
                            "Enter your Private Key ID",
                            text: $settingsManager.config.privateKeyID
                        )
                        .textFieldStyle(.roundedBorder)
                        .help("The ID of your private key")
                    }

                    // Private Key
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Private Key", systemImage: "doc.text")
                                .font(.headline)
                            if !settingsManager.config.privateKey.isEmpty {
                                Text("Private key loaded successfully")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        .green.opacity(0.1),
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                            }
                            Spacer(minLength: 0)
                        }

                        HStack {
                            Button("Choose Private Key File") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.bordered)

                            if !settingsManager.config.privateKey.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text("Key loaded")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Status Section
                VStack(spacing: 16) {
                    HStack {
                        Label("Connection Status", systemImage: "wifi")
                            .font(.headline)

                        Spacer()

                        HStack(spacing: 8) {
                            Circle()
                                .fill(settingsManager.isConfigured ? .green : .red)
                                .frame(width: 12, height: 12)
                                .symbolEffect(.pulse, isActive: settingsManager.isConfigured)

                            Text(settingsManager.isConfigured ? "Configured" : "Not Configured")
                                .fontWeight(.medium)
                                .foregroundStyle(settingsManager.isConfigured ? .green : .red)
                        }
                    }

                    if let testResult = testResult {
                        HStack {
                            Image(
                                systemName: testResult.contains("Success")
                                    ? "checkmark.circle.fill" : "xmark.circle.fill"
                            )
                            .foregroundStyle(testResult.contains("Success") ? .green : .red)

                            Text(testResult)
                                .font(.caption)
                                .foregroundStyle(testResult.contains("Success") ? .green : .red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    testResult.contains("Success")
                                        ? .green.opacity(0.1) : .red.opacity(0.1)
                                )
                        )
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
        }
        .scrollBounceBehavior(.basedOnSize)
        .maxFrame()
    }

    private func testConnection() {
        isTestingConnection = true
        testResult = nil

        Task {
            apiService.configure(
                issuerID: settingsManager.config.issuerID,
                privateKeyID: settingsManager.config.privateKeyID,
                privateKey: settingsManager.config.privateKey
            )

            let success = await apiService.testConnection()

            await MainActor.run {
                testResult =
                    success
                    ? "✅ Connection successful!" : "❌ Connection failed. Check your credentials."
                isTestingConnection = false
            }
        }
    }
}
