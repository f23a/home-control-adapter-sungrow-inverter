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
    private var homeControlClient: HomeControlClient
    private var sungrowClient: SungrowClient
    private let jobRunner = JobRunner()
    private(set) var updateInverterReadingJob: UpdateInverterReadingJob!
    private(set) var forceChargerJob: ForceChargerJob!

    init() {
        homeControlClient = HomeControlClient.localhost
        sungrowClient = SungrowClient(address: HomeControlKit.Environment.require("SUNGROW_INVERTER_IP"))
        homeControlClient.authToken = HomeControlKit.Environment.require("AUTH_TOKEN")

        updateInverterReadingJob = .init(sungrowClient: sungrowClient, homeControlClient: homeControlClient)
        forceChargerJob = .init(sungrowClient: sungrowClient, homeControlClient: homeControlClient)

        jobRunner.append(job: updateInverterReadingJob)
        jobRunner.append(job: forceChargerJob)
    }

    var updateInverterReadingTableData: TableData {
        .init(title: "Update Inverter Reading") { rows in
            rows.append(title: "Last Run", updateInverterReadingJob.lastRun) { lastRun in
                Text(lastRun, style: .relative)
            }
            rows.append(title: "Last Success", updateInverterReadingJob.lastSuccess) { lastSuccess in
                Text(lastSuccess, style: .relative)
            }
            rows.append(
                title: "ID",
                value: updateInverterReadingJob.lastStoredInverterReading?.id.uuidString
            )
            rows.append(
                title: "Battery",
                value: updateInverterReadingJob.lastStoredInverterReading?.value.formatted(\.batteryLevel)
            )
        }
    }

    var forceChargerTableData: TableData {
        .init(title: "Force Charger") { rows in
            rows.append(title: "Last Run", forceChargerJob.lastRun) { lastRun in
                Text(lastRun, style: .relative)
            }
        }
    }
}
