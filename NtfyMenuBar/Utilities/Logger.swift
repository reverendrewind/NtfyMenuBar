//
//  Logger.swift
//  NtfyMenuBar
//
//  Created by Rimskij Papa on 24/09/2025.
//

import Foundation
import os.log

enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
}

class Logger {
    static let shared = Logger()

    private let osLog = OSLog(subsystem: "net.raczej.NtfyMenuBar", category: "app")

    private init() {}

    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        log(level: .debug, message: message, file: file, function: function, line: line)
        #endif
    }

    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }

    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }

    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }

    private func log(level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
        let logMessage = "[\(level.rawValue)] \(fileName).\(function):\(line) - \(message)"

        // Use os_log for proper system integration
        switch level {
        case .debug:
            os_log("%{public}@", log: osLog, type: .debug, logMessage)
        case .info:
            os_log("%{public}@", log: osLog, type: .info, logMessage)
        case .warning:
            os_log("%{public}@", log: osLog, type: .error, logMessage)
        case .error:
            os_log("%{public}@", log: osLog, type: .fault, logMessage)
        }
    }
}