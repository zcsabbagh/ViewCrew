//
//  StocksWidget2.swift
//  StocksWidget2
//
//  Created by Zane Sabbagh on 7/18/24.
//

import WidgetKit
import SwiftUI

struct StocksWidget2: Widget {
    let kind: String = "StocksWidget2"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StocksWidget2EntryView(entry: entry)
        }
        .configurationDisplayName("Streaming history")
        .description("See what your friends are streaming")
        .supportedFamilies([.systemSmall])
    }
}