//
//  ContentView.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 28.09.24.
//

import HomeControlKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()

    var body: some View {
        VStack {
            TableView(table: viewModel.updateInverterReadingTableData)
            TableView(table: viewModel.forceChargerTableData)
        }
        .tableStyle(.bordered)
        .padding()
    }
}

#Preview {
    ContentView()
}
