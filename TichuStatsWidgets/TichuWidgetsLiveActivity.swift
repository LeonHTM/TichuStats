//
//  TichuWidgetsLiveActivity.swift
//  TichuStatsWidgets
//
//  Created by Leon on 03.06.2026.
//

import ActivityKit
import WidgetKit
import SwiftUI


//Template for Live Activity
struct TichuWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct TichuWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TichuWidgetsAttributes.self) { context in
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

extension TichuWidgetsAttributes {
    fileprivate static var preview: TichuWidgetsAttributes {
        TichuWidgetsAttributes(name: "World")
    }
}

extension TichuWidgetsAttributes.ContentState {
    fileprivate static var smiley: TichuWidgetsAttributes.ContentState {
        TichuWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: TichuWidgetsAttributes.ContentState {
         TichuWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: TichuWidgetsAttributes.preview) {
   TichuWidgetsLiveActivity()
} contentStates: {
    TichuWidgetsAttributes.ContentState.smiley
    TichuWidgetsAttributes.ContentState.starEyes
}
