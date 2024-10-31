//
//  UpdateInverterReadingJob.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 12.10.24.
//

import Foundation
import HomeControlClient
import HomeControlKit
import  Logging
import SungrowKit

@Observable
class UpdateInverterReadingJob: Job {
    private let logger = Logger(adapterSungrowInverter: "update-inverter-reading-job")
    private var sungrowClient: SungrowClient
    private var homeControlClient: HomeControlClient
    private(set) var lastSuccess: Date?
    private(set) var lastStoredInverterReading: Stored<InverterReading>?

    init(sungrowClient: SungrowClient, homeControlClient: HomeControlClient) {
        self.sungrowClient = sungrowClient
        self.homeControlClient = homeControlClient

        super.init(maxAge: 2)
    }

    override func run() async {
        do {
            if !sungrowClient.isConnected {
                logger.info("Connect Sungrow client")
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

            let inverterReading = InverterReading(
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

            func f(_ keyPath: KeyPath<InverterReading, Double>) -> String {
                inverterReading.formatted(keyPath, options: .short)
            }

            logger.info("""
            Updated Inverter Reading
            From: Solar: \(f(\.fromSolar)), Grid: \(f(\.fromGrid)), Battery: \(f(\.fromBattery))
            To: Load: \(f(\.toLoad)), Grid: \(f(\.toGrid)), Battery: \(f(\.toBattery))
            Battery: \(f(\.batteryLevel))
            """)

            let storedInverterReading = try await homeControlClient.inverterReading.create(inverterReading)
            logger.info("Stored Inverter Reading \(storedInverterReading.id)")

            lastSuccess = Date()
            lastStoredInverterReading = storedInverterReading
        } catch {
            logger.error("Failed to update: \(error)")
        }
    }
}
