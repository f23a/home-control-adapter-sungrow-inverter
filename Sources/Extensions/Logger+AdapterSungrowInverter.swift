//
//  Logger+AdapterSungrowInverter.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 26.10.24.
//

import Logging

extension Logger {
    init(adapterSungrowInverter label: String) {
        self.init(label: "de.pageler.christoph.home-control.adapter-sungrow-inverter.\(label)")
    }
}
