//
//  addInsulin.swift
//  App
//
//  Created by Paul Silver on 27/06/2022.
//


import SwiftUI

// MARK: - ConnectionView

struct AddInsulinView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        Section(
            content: {
                if store.state.isConnectionPaired {
                    HStack {
                        Text("Add SOme INsulin")
                        Spacer()
                        Text(store.state.connectionState.localizedString)
                    }

                    if store.state.missedReadings > 0 {
                        HStack {
                            Text("Missed Iiiinsulinsdf")
                            Spacer()
                            Text(store.state.missedReadings.description)
                        }
                    }
                }

                Text("This")
                Text("is")
                Text("a")
                Text("View")
            },
            header: {
                Label("Add Insulin", systemImage: "rectangle.connected.to.line.below")
            }
        )
    }
}
