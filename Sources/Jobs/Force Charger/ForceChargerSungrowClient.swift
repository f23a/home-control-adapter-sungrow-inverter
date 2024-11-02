//
//  ForceChargerSungrowClient.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 01.11.24.
//

import SungrowKit
import Logging

struct ForceChargerSungrowClient: ForceChargerSungrow {
    private let logger = Logger(adapterSungrowInverter: "force-charger-sungrow-fake")
    let sungrowClient: SungrowClient

    private func connectSungrowClientIfNeeded() throws {
        if !sungrowClient.isConnected {
            logger.info("Connect Sungrow client")
            try sungrowClient.connect()
        }
    }


    func isForceChargingEnabled() async throws -> Bool {
        try connectSungrowClientIfNeeded()
        return try await sungrowClient.read(request: .forcedCharging)
    }

    func disableForceCharging() async throws {
        try connectSungrowClientIfNeeded()
        try await sungrowClient.write(request: .forcedCharging(isEnabled: false))
    }

    func enableForceCharging(
        forcedCharging1: SungrowForcedCharging,
        forcedCharging2: SungrowForcedCharging
    ) async throws {
        try connectSungrowClientIfNeeded()
        try await sungrowClient.write(request: .forcedCharging1(forcedCharging1))
        try await sungrowClient.write(request: .forcedCharging2(forcedCharging2))
        try await sungrowClient.write(request: .forcedCharging(isEnabled: true))
    }
}
