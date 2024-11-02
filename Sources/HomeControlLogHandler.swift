//
//  HomeControlLogHandler.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 01.11.24.
//

import Foundation
import Logging

struct HomeControlLogHandler: LogHandler {
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { self.metadata[metadataKey] }
        set { self.metadata[metadataKey] = newValue }
    }

    var metadata: Logger.Metadata
    var logLevel: Logger.Level
    var label: String

    private let dateFormatter = DateFormatter()

    public init(logLevel: Logger.Level = .info, label: String) {
        self.metadata = [:]
        self.logLevel = logLevel
        self.label = label

        dateFormatter.dateFormat = "HH:mm:ss"
    }

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt)
    {
        print("[\(level.rawValue.uppercased())] \(dateFormatter.string(from: Date())) \(message)")
    }
}

