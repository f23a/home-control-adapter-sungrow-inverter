//
//  ForceChargerSungrow.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 01.11.24.
//

import SungrowKit

protocol ForceChargerSungrow {
    func isForceChargingEnabled() async throws -> Bool
    func disableForceCharging() async throws
    func enableForceCharging(
        forcedCharging1: SungrowForcedCharging,
        forcedCharging2: SungrowForcedCharging
    ) async throws
}
