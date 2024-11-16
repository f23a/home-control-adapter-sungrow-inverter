//
//  ForceChargerJob.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 12.10.24.
//

import Foundation
import HomeControlClient
import HomeControlKit
import HomeControlLogging
import Logging
import SungrowKit

class ForceChargerJob: Job {
    private let logger = Logger(homeControl: "adapter-sungrow-inverter.force-charger-job")
    private var sungrow: ForceChargerSungrow
    private var homeControlClient: HomeControlClient

    init(sungrow: ForceChargerSungrow, homeControlClient: HomeControlClient) {
        self.sungrow = sungrow
        self.homeControlClient = homeControlClient

        super.init(maxAge: 10.seconds)
    }

    override func run() async {
        do {
            logger.info("Run force charger")
            let forceCharger = ForceCharger(provider: self)

            let result = try await forceCharger.execute()
            switch result {
            case .skip(let reason):
                logger.info("Skip: \(reason)")
                if reason == .waitForMinimumOfRanges {
                    logger.info("Check if force charging disable is needed")
                    try await disableForceChargingIfNeeded()
                }
            case .send(let ranges):
                logger.info("Send \(ranges.count) ranges")
                try await send(ranges: ranges)
            }
        } catch {
            logger.error("Failed to execute force charger \(error)")
        }
    }

    private func disableForceChargingIfNeeded() async throws {
        let forceCharging = try await sungrow.isForceChargingEnabled()
        logger.info("Force Charging is \(forceCharging ? "enabled" : "disabled")")
        if forceCharging {
            logger.info("Disable force charging")
            try await sungrow.disableForceCharging()

            let message = Message(
                type: .inverterForceChargingDisabled,
                title: "Zwangsladung deaktiviert",
                body: "Die Zwangsladung wurde deaktiviert, da keine aktuelle Planung existiert."
            )
            let createdMessage = try await homeControlClient.messages.create(message)
            try await homeControlClient.messages.sendPushNotifications(id: createdMessage.id)
        }
    }

    private func send(ranges: [Stored<ForceChargingRange>]) async throws {
        let range1 = ranges[safe: 0]
        let range2 = ranges[safe: 1]
        let sungrowForcedCharging1 = range1?.value.sungrowForcedCharging() ?? .empty
        let sungrowForcedCharging2 = range2?.value.sungrowForcedCharging() ?? .empty

        try await sungrow.enableForceCharging(
            forcedCharging1: sungrowForcedCharging1,
            forcedCharging2: sungrowForcedCharging2
        )
        try await updateRange(range1)
        try await updateRange(range2)

        let message = Message(
            type: .inverterForceChargingEnabled,
            title: "Zwangsladung aktiviert",
            body: "Die Zwangsladung wurde aktiviert. \(sungrowForcedCharging1.debugDescription) \(sungrowForcedCharging2.debugDescription)"
        )
        let createdMessage = try await homeControlClient.messages.create(message)
        try await homeControlClient.messages.sendPushNotifications(id: createdMessage.id)
    }

    private func updateRange(_ storedRange: Stored<ForceChargingRange>?) async throws {
        guard let storedRange else { return }
        var range = storedRange.value
        range.state = .sent
        logger.info("Update range to state sent")
        try await homeControlClient.forceChargingRanges.update(id: storedRange.id, range)
    }
}

extension ForceChargerJob: ForceChargerRangeProvider {
    func forceChargingRanges(in range: Range<Date>) async throws -> [Stored<ForceChargingRange>] {
        let query = ForceChargingRangeQuery(
            pagination: .init(page: 0, per: 1000),
            filter: [
                .startsAt(.init(value: range.upperBound, method: .lessThanOrEqual)),
                .endsAt(.init(value: range.lowerBound, method: .greaterThanOrEqual))
            ],
            sort: .init(value: .startsAt, direction: .ascending)
        )
        let page = try await homeControlClient.forceChargingRanges.query(query)
        return page.items
    }
}

extension ForceChargingRange {
    func sungrowForcedCharging(calendar: Calendar = .current) -> SungrowForcedCharging? {
        let startsAtComponents = Calendar.current.dateComponents([.hour, .minute], from: startsAt)
        let endsAtComponents = Calendar.current.dateComponents([.hour, .minute], from: endsAt)
        guard
            let startHour = startsAtComponents.hour,
            let startMinute = startsAtComponents.minute,
            let endHour = endsAtComponents.hour,
            let endMinute = endsAtComponents.minute
        else {
            return nil
        }

        return .init(
            from: .init(hour: startHour, minute: startMinute),
            to: .init(hour: endHour, minute: endMinute),
            targetSoc: targetStateOfCharge
        )
    }
}

extension SungrowForcedCharging {
    static var empty: Self { .init(from: .init(hour: 0, minute: 0), to: .init(hour: 0, minute: 0), targetSoc: 0) }
}
