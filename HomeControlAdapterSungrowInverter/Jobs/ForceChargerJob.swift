//
//  ForceChargerJob.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 12.10.24.
//

import Foundation
import HomeControlClient
import HomeControlKit
import SungrowKit

class ForceChargerJob: Job {
    private var sungrowClient: SungrowClient
    private var homeControlClient: HomeControlClient

    init(sungrowClient: SungrowClient, homeControlClient: HomeControlClient) {
        self.sungrowClient = sungrowClient
        self.homeControlClient = homeControlClient

        super.init(maxAge: 10.seconds)
    }

    override func run() async {
        do {
            print("Run force charger")
            let forceCharger = ForceCharger(provider: self)

            let result = try await forceCharger.execute()
            switch result {
            case .skip(let reason):
                print("Skip: \(reason)")
                if reason == .waitForMinimumOfRanges {
                    print("Check if force charging disable is needed")
                    try await disableForceChargingIfNeeded()
                }
            case .send(let ranges):
                print("Send \(ranges.count) ranges")
                try await send(ranges: ranges)
            }
        } catch {
            print("Failed to execute force charger \(error)")
        }
    }

    private func connectSungrowClientIfNeeded() throws {
        if !sungrowClient.isConnected {
            print("Connect Sungrow client")
            try sungrowClient.connect()
        }
    }

    private func disableForceChargingIfNeeded() async throws {
        try connectSungrowClientIfNeeded()
        let forceCharging = try await sungrowClient.read(request: .forcedCharging)
        if forceCharging {
            print("Disable force charging")
            try await sungrowClient.write(request: .forcedCharging(isEnabled: false))

            let message = Message(
                title: "Zwangsladung deaktiviert",
                body: "Die Zwangsladung wurde deaktiviert, da keine aktuelle Planung existiert."
            )
            let createdMessage = try await homeControlClient.messages.create(message)
            try await homeControlClient.messages.sendPushNotifications(id: createdMessage.id)
        }
    }

    private func send(ranges: [Stored<ForceChargingRange>]) async throws {
        try connectSungrowClientIfNeeded()
        let range1 = ranges[safe: 0]
        let range2 = ranges[safe: 1]
        let sungrowForcedCharging1 = range1?.value.sungrowForcedCharging() ?? .empty
        let sungrowForcedCharging2 = range2?.value.sungrowForcedCharging() ?? .empty

        try await sungrowClient.write(request: .forcedCharging1(sungrowForcedCharging1))
        try await updateRange(range1)
        try await sungrowClient.write(request: .forcedCharging2(sungrowForcedCharging2))
        try await updateRange(range2)
        try await sungrowClient.write(request: .forcedCharging(isEnabled: true))

        let message = Message(
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
        print("Update range to state sent")
        try await homeControlClient.forceChargingRanges.update(id: storedRange.id, range)
    }
}

extension ForceChargerJob: ForceChargerRangeProvider {
    func forceChargingRanges(in range: Range<Date>) async throws -> [Stored<ForceChargingRange>] {
        let query = ForceChargingRangeQuery(
            range: .init(
                startsAt: range.lowerBound,
                endsAt: range.upperBound
            )
        )
        return try await homeControlClient.forceChargingRanges.query(query)
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
