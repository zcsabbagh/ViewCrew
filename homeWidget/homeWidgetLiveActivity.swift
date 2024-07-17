//
//  homeWidgetLiveActivity.swift
//  homeWidget
//
//  Created by Zane Sabbagh on 7/9/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct homeWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct homeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: homeWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension homeWidgetAttributes {
    fileprivate static var preview: homeWidgetAttributes {
        homeWidgetAttributes(name: "World")
    }
}

extension homeWidgetAttributes.ContentState {
    fileprivate static var smiley: homeWidgetAttributes.ContentState {
        homeWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: homeWidgetAttributes.ContentState {
         homeWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: homeWidgetAttributes.preview) {
   homeWidgetLiveActivity()
} contentStates: {
    homeWidgetAttributes.ContentState.smiley
    homeWidgetAttributes.ContentState.starEyes
}
