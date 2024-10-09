//
//  ContentView.swift
//  HomeControlAdapterSungrowInverter
//
//  Created by Christoph Pageler on 28.09.24.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = ContentViewModel()

    var body: some View {
        Form {
            VStack(alignment: .leading, spacing: 20) {
                Stepper(value: $viewModel.updateTimerInterval, in: 1...10, step: 1) {
                    HStack {
                        Text("Update Timer Interval")
                        Text("\(Int(viewModel.updateTimerInterval))").bold()
                    }
                }
                HStack {
                    Button("Start Update", action: viewModel.startTimer)
                        .disabled(viewModel.isTimerRunning)
                    Button("Stop Update", action: viewModel.stopTimer)
                        .disabled(!viewModel.isTimerRunning)
                }
                HStack {
                    Text("Last Success:")
                    if let lastSuccess = viewModel.lastSuccess {
                        Text(lastSuccess, style: .relative)
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
