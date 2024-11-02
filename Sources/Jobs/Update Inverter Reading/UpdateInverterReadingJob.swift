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
    private var sungrow: UpdateInverterReadingSungrow
    private var homeControlClient: HomeControlClient
    private(set) var lastSuccess: Date?
    private(set) var lastStoredInverterReading: Stored<InverterReading>?

    init(sungrow: UpdateInverterReadingSungrow, homeControlClient: HomeControlClient) {
        self.sungrow = sungrow
        self.homeControlClient = homeControlClient

        super.init(maxAge: 2)
    }

    override func run() async {
        do {
            let inverterReading = try await sungrow.inverterReading()

            func f(_ keyPath: KeyPath<InverterReading, Double>) -> String {
                inverterReading.formatted(keyPath, options: .short)
            }

            logger.info("Updated Inverter Reading")
            logger.info("From: Solar: \(f(\.fromSolar)), Grid: \(f(\.fromGrid)), Battery: \(f(\.fromBattery))")
            logger.info("To: Load: \(f(\.toLoad)), Grid: \(f(\.toGrid)), Battery: \(f(\.toBattery))")
            logger.info("Battery: \(f(\.batteryLevel))")

            let storedInverterReading = try await homeControlClient.inverterReading.create(inverterReading)
            logger.info("Stored Inverter Reading \(storedInverterReading.id)")

            lastSuccess = Date()
            lastStoredInverterReading = storedInverterReading
        } catch {
            logger.error("- Failed to update: \(error)")
        }
    }
}
