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
import SungrowKit

@main
struct MainCommand: AsyncParsableCommand {
    func run() async throws {
        let dotEnv = try DotEnv.fromWorkingDirectory()
        var homeControlClient = HomeControlClient.localhost
        let sungrowClient = SungrowClient(address: try dotEnv.require("SUNGROW_INVERTER_IP"))
        homeControlClient.authToken = try dotEnv.require("AUTH_TOKEN")

        let jobs: [Job] = [
            UpdateInverterReadingJob(sungrowClient: sungrowClient, homeControlClient: homeControlClient),
            ForceChargerJob(sungrowClient: sungrowClient, homeControlClient: homeControlClient)
        ]

        while true {
            for job in jobs {
                await job.runIfNeeded(at: Date())
            }
            await Task.sleep(1.seconds)
        }
    }
}
