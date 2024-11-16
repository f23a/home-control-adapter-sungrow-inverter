//
//  MainCommand.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 31.10.24.
//

import ArgumentParser
import Foundation
import HomeControlClient
import HomeControlKit
import HomeControlLogging
import Logging
import SungrowKit

@main
struct MainCommand: AsyncParsableCommand {
    private static let logger = Logger(homeControl: "adapter-sungrow-inverter.main-command")

    @Flag(help: "Run without update inverter reading job")
    var noUpdate = false

    @Flag(help: "Run without force charger job")
    var noForceCharger = false

    @Flag(help: "Run in development mode (fake connection to sungrow inverter)")
    var development = false

    func run() async throws {
        LoggingSystem.bootstrapHomeControl()

        // Load environment from .env.json
        let dotEnv = try DotEnv.fromWorkingDirectory()

        // Prepare home control client
        var homeControlClient = HomeControlClient.localhost
        homeControlClient.authToken = try dotEnv.require("AUTH_TOKEN")

        // Prepare Sungrow for jobs
        let updateInverterReadingSungrow: UpdateInverterReadingSungrow
        let forceChargerSungrow: ForceChargerSungrow
        if development {
            Self.logger.info("Run in development mode: FAKE Sungrow Inverter")
            updateInverterReadingSungrow = UpdateInverterReadingSungrowFake(homeControlClient: homeControlClient)
            forceChargerSungrow = ForceChargerSungrowFake()
        } else {
            Self.logger.info("Run in production mode: REAL Sungrow Inverter")
            let sungrowClient = SungrowClient(address: try dotEnv.require("SUNGROW_INVERTER_IP"))
            updateInverterReadingSungrow = UpdateInverterReadingSungrowClient(sungrowClient: sungrowClient)
            forceChargerSungrow = ForceChargerSungrowClient(sungrowClient: sungrowClient)
        }

        // Prepare jobs
        var jobs: [Job] = []

        // Add update inverter reading job if needed
        if !noUpdate {
            Self.logger.info("Add Update Inverter Reading Job")
            jobs.append(
                UpdateInverterReadingJob(
                    sungrow: updateInverterReadingSungrow,
                    homeControlClient: homeControlClient
                )
            )
        }

        // Add force charger job if needed
        if !noForceCharger {
            Self.logger.info("Add Force Charger Job")
            jobs.append(ForceChargerJob(sungrow: forceChargerSungrow, homeControlClient: homeControlClient))
        }

        // Ensure jobs is not empty
        guard !jobs.isEmpty else {
            Self.logger.critical("No Jobs")
            return
        }

        // run jobs until command is canceled using ctrl + c
        while true {
            for job in jobs {
                await job.runIfNeeded(at: Date())
            }
            await Task.sleep(1.seconds)
        }
    }
}
