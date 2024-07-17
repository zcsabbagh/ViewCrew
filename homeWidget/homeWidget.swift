//
//  homeWidget.swift
//  homeWidget
//
//  Created by Zane Sabbagh on 7/9/24.
//

import WidgetKit
import SwiftUI
import SDWebImageSwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "😀")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "😀")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, emoji: "😀")
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct homeWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        widget1
    }
    
    var widget1: some View {
        VStack {
            Text("Time:")
            Text(entry.date, style: .time)
            WebImage(url: URL(string: "https://firebasestorage.googleapis.com:443/v0/b/candid2024-9f0fc.appspot.com/o/userImages%2FB4D1D7EF-EF9F-465E-BAC4-755B865A7C7C.jpg?alt=media&token=53ffb124-2c18-4f7c-befd-2c1aad330f02"))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            Text("Emoji:")
            Text(entry.emoji)
            
            
        }
        
    }
}

struct homeWidget: Widget {
    let kind: String = "homeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                homeWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                homeWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

#Preview(as: .systemSmall) {
    homeWidget()
} timeline: {
    SimpleEntry(date: .now, emoji: "😀")
    SimpleEntry(date: .now, emoji: "🤩")
}
