//
//  Log.swift
//  Release
//
//  Created by Roger on 2025/10/18.
//  Copyright © 2025 Ideas Form. All rights reserved.
//

import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? Bundle.main.bundleURL.lastPathComponent
    static let general = Logger(subsystem: subsystem, category: "general")
}

public let log = Log.self

public struct Log {
    static let prefix = "💬 "
    public static func debug(_ message: @autoclosure () -> Any) {
        #if DEBUG
        let evalMessage = "\(message())"
        Logger.general.debug("\(prefix)\(evalMessage)")
        #endif
    }

    public static func warning(_ message: @autoclosure () -> Any) {
        #if DEBUG
        let evalMessage = "\(message())"
        Logger.general.warning("\(prefix)\(evalMessage)")
        #endif
    }

    public static func error(_ message: @autoclosure () -> Any) {
        #if DEBUG
        let evalMessage = "\(message())"
        Logger.general.error("\(prefix)\(evalMessage)")
        #endif
    }

}
