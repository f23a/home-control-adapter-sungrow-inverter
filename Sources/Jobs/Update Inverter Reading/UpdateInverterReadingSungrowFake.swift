//
//  UpdateInverterReadingSungrowFake.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 31.10.24.
//

import HomeControlClient
import HomeControlKit

/// `UpdateInverterReadingSungrowFake` just provides the latest inverter reading from client
struct UpdateInverterReadingSungrowFake: UpdateInverterReadingSungrow {
    let homeControlClient: HomeControlClient

    func inverterReading() async throws -> InverterReading {
        try await homeControlClient.inverterReading.latest().value
    }
}
