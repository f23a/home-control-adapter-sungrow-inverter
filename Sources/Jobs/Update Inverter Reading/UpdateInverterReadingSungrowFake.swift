//
//  UpdateInverterReadingSungrowFake.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 31.10.24.
//

import Foundation
import HomeControlClient
import HomeControlKit

/// `UpdateInverterReadingSungrowFake` just provides the latest inverter reading from client
struct UpdateInverterReadingSungrowFake: UpdateInverterReadingSungrow {
    let homeControlClient: HomeControlClient

    func inverterReading() async throws -> InverterReading {
        guard var latest = try await homeControlClient.inverterReading.latest()?.value else {
            throw UpdateInverterReadingSungrowFakeError.noLatest
        }
        latest.readingAt = Date()
        return latest
    }
}

enum UpdateInverterReadingSungrowFakeError: Error {
    case noLatest
}
