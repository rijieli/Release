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
        
        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let refreshApps = Notification.Name("refreshApps")
}
