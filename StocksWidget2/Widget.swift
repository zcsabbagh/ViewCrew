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
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            StocksWidget2EntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streaming history")
        .description("See what your friends are streaming")
        .supportedFamilies([.systemLarge, .systemSmall]) 
    }
}
extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.selectedFriend = .all
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.selectedFriend = .zane
        return intent
    }
}

//#Preview(as: .systemSmall) {
//    StocksWidget2()
//} timeline: {
//    SimpleEntry(date: .now, configuration: .smiley, post: nil, previewImageData: nil, profileImageData: nil)
//    SimpleEntry(date: .now, configuration: .starEyes, post: nil, previewImageData: nil, profileImageData: nil)
//}
