//
//  UpdateInverterReadingSungrow.swift
//  home-control-adapter-sungrow-inverter
//
//  Created by Christoph Pageler on 31.10.24.
//

import HomeControlKit

protocol UpdateInverterReadingSungrow {
    func inverterReading() async throws -> InverterReading
}
