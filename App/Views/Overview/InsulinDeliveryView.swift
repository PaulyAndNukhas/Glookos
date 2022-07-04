//
//  InsulinDelivery.swift
//  GlucoseDirectApp
//
//  Created by Paul Silver on 02/07/2022.
//

import Foundation
import SwiftUI

struct InsulinDeliveryView: View {
    
    var body: some View {
        Section(
            content: {
                VStack {
                    Text("Hello")
                    Text("World")
                }
            },
            header: {
                Label("Insulin Delievery", systemImage: "chart.xyaxis.line")
            }
        )
    }
}
