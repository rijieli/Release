//
//  ReleaseApp.swift
//  Release
//
//  Created by Roger on 2025/10/6.
//

import SwiftUI

let kMainWindowID = "Window.Main"

@main
struct ReleaseApp: App {
    var body: some Scene {
        WindowGroup("Release", id: kMainWindowID) {
            ContentView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Release") {
                    // Handle about action
                }
            }
            
            CommandGroup(after: .toolbar) {
                Button("Refresh Apps") {
                    NotificationCenter.default.post(name: .refreshApps, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        
        // App Detail Window
        WindowGroup("App Details", id: "app-detail") {
            if let appInfo = AppDetailManager.shared.selectedApp {
                AppDetailView(appInfo: appInfo)
            } else {
                Text("No app selected")
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 600, minHeight: 400)
            }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        
        Settings {
            SettingsView()
                .frame(width: 600, height: 400)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let refreshApps = Notification.Name("refreshApps")
}
