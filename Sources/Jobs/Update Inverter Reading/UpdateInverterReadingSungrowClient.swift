//
//  UpdateInverterReadingSungrowClient.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 31.10.24.
//

import Foundation
import SungrowKit
import HomeControlKit

struct UpdateInverterReadingSungrowClient: UpdateInverterReadingSungrow {
    var sungrowClient: SungrowClient

    func inverterReading() async throws -> InverterReading {
        if !sungrowClient.isConnected {
            try sungrowClient.connect()
        }

        let powerFlow = try await self.sungrowClient.readPowerFlow()
        let batteryLevel = try await self.sungrowClient.read(request: .batteryLevel)
        let batteryHealth = try await self.sungrowClient.read(request: .batteryHealth)
        let batteryTemperature = try await self.sungrowClient.read(request: .batteryTemperature)
        let dailyPVGeneration = try await self.sungrowClient.read(request: .dailyPvGeneration)
        let dailyImportEnergy = try await self.sungrowClient.read(request: .dailyImportEnergy)
        let dailyExportEnergy = try await self.sungrowClient.read(request: .dailyExportEnergy)
        let dailyDirectEnergyConsumption = try await self.sungrowClient.read(request: .dailyDirectEnergyConsumption)
        let dailyBatteryDischargeEnergy = try await self.sungrowClient.read(request: .dailyBatteryDischargeEnergy)

        return InverterReading(
            readingAt: Date(),
            solarToBattery: powerFlow.output.solarToBattery,
            solarToLoad: powerFlow.output.solarToLoad,
            solarToGrid: powerFlow.output.solarToGrid,
            batteryToLoad: powerFlow.output.batteryToLoad,
            batteryToGrid: powerFlow.output.batteryToGrid,
            gridToBattery: powerFlow.output.gridToBattery,
            gridToLoad: powerFlow.output.gridToLoad,
            batteryLevel: batteryLevel.value / 100.0,
            batteryHealth: batteryHealth.value / 100.0,
            batteryTemperature: batteryTemperature.value,
            dailyPVGeneration: dailyPVGeneration.value,
            dailyImportEnergy: dailyImportEnergy.value,
            dailyExportEnergy: dailyExportEnergy.value,
            dailyDirectEnergyConsumption: dailyDirectEnergyConsumption.value,
            dailyBatteryDischargeEnergy: dailyBatteryDischargeEnergy.value
        )
    }
}
