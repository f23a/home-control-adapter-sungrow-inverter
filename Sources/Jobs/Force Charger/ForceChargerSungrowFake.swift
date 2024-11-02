//
//  ForceChargerSungrowFake.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 01.11.24.
//


import SungrowKit

class ForceChargerSungrowFake: ForceChargerSungrow {
    private var isEnabled = false

    func isForceChargingEnabled() async throws -> Bool { isEnabled }

    func disableForceCharging() async throws {
        isEnabled = false
    }

    func enableForceCharging(
        forcedCharging1: SungrowForcedCharging,
        forcedCharging2: SungrowForcedCharging
    ) async throws {
        isEnabled = true
    }
}
