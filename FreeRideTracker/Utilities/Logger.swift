//
//  Logger.swift
//  FreeRideTracker
//
//  Created by Refactoring on 2025-11-28.
//

import Foundation
import os.log

/// Centralized logging system for the app using OSLog
/// Provides privacy-aware logging with different severity levels
enum AppLogger {
    
    // MARK: - Subsystems
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.freeride.tracker"
    
    static let location = Logger(subsystem: subsystem, category: "Location")
    static let data = Logger(subsystem: subsystem, category: "Data")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let auth = Logger(subsystem: subsystem, category: "Authentication")
    static let background = Logger(subsystem: subsystem, category: "Background")
    static let general = Logger(subsystem: subsystem, category: "General")
    
    // MARK: - Convenience Methods
    
    /// Log a debug message (only visible in debug builds)
    static func debug(_ message: String, category: Logger, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        category.debug("[\(fileName):\(line)] \(function) - \(message)")
        #endif
    }
    
    /// Log an informational message
    static func info(_ message: String, category: Logger) {
        category.info("\(message)")
    }
    
    /// Log a warning message
    static func warning(_ message: String, category: Logger, file: String = #file, function: String = #function) {
        let fileName = (file as NSString).lastPathComponent
        category.warning("[\(fileName)] \(function) - \(message)")
    }
    
    /// Log an error message
    static func error(_ message: String, error: Error? = nil, category: Logger, file: String = #file, function: String = #function) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            category.error("[\(fileName)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            category.error("[\(fileName)] \(function) - \(message)")
        }
    }
    
    /// Log a critical error that requires immediate attention
    static func critical(_ message: String, error: Error? = nil, category: Logger, file: String = #file, function: String = #function) {
        let fileName = (file as NSString).lastPathComponent
        if let error = error {
            category.critical("[\(fileName)] \(function) - \(message): \(error.localizedDescription)")
        } else {
            category.critical("[\(fileName)] \(function) - \(message)")
        }
    }
}

// MARK: - Performance Logging

extension AppLogger {
    
    /// Measure and log the execution time of a code block
    static func measure<T>(_ operation: String, category: Logger, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            category.info("⏱️ \(operation) took \(String(format: "%.3f", timeElapsed))s")
        }
        return try block()
    }
    
    /// Measure and log the execution time of an async code block
    static func measureAsync<T>(_ operation: String, category: Logger, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
            category.info("⏱️ \(operation) took \(String(format: "%.3f", timeElapsed))s")
        }
        return try await block()
    }
}
