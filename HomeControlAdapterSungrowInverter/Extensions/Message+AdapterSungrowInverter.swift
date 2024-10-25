//
//  Message+AdapterSungrowInverter.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 25.10.24.
//

import HomeControlKit

extension Message {
    init(title: String, body: String) {
        self.init(type: .adapterSungrowInverter, title: title, body: body)
    }
}
