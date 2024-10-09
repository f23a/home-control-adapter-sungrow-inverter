//
//  ContentViewModel.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 28.09.24.
//

import HomeControlClient
import HomeControlKit
import SungrowKit
import SwiftUI

@Observable final class ContentViewModel {
    private var sungrowClient: SungrowClient
    private var homeControlClient: HomeControlClient

    init() {
        sungrowClient = SungrowClient(address: "192.168.178.73")
        homeControlClient = HomeControlClient.localhost
        homeControlClient.authToken = HomeControlKit.Environment.require("AUTH_TOKEN")
    }

    var updateTimerInterval: TimeInterval = 2.0 {
        didSet {
            refreshTimerIfNeeded()
        }
    }
    var isTimerRunning: Bool { updateTimer != nil }
    var updateTimer: Timer?

    private(set) var lastSuccess: Date?

    func startTimer() {
        stopTimer()
        updateTimer = .scheduledTimer(withTimeInterval: updateTimerInterval, repeats: true) { [weak self] _ in
            self?.fireTimer()
        }
    }

    func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func refreshTimerIfNeeded() {
        guard isTimerRunning else { return }
        startTimer()
    }

    private func fireTimer() {
        Task {
            do {
                if !sungrowClient.isConnected {
                    print("Connect Sungrow client")
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

                print("""
                Updated Inverter Reading
                From: Solar: \(f(\.fromSolar)), Grid: \(f(\.fromGrid)), Battery: \(f(\.fromBattery))
                To: Load: \(f(\.toLoad)), Grid: \(f(\.toGrid)), Battery: \(f(\.toBattery))
                Battery: \(f(\.batteryLevel))
                """)

                let storedInverterReading = try await homeControlClient.inverterReading.create(inverterReading)
                print("Stored Inverter Reading \(storedInverterReading.id)")

                lastSuccess = Date()

            } catch {
                print("Failed to update: \(error)")
            }
        }
    }
}
