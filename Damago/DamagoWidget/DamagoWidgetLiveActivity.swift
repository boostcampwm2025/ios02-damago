//
//  DamagoWidgetLiveActivity.swift
//  DamagoWidget
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DamagoWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DamagoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DamagoWidgetAttributes.self) { context in
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

extension DamagoWidgetAttributes {
    fileprivate static var preview: DamagoWidgetAttributes {
        DamagoWidgetAttributes(name: "World")
    }
}

extension DamagoWidgetAttributes.ContentState {
    fileprivate static var smiley: DamagoWidgetAttributes.ContentState {
        DamagoWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DamagoWidgetAttributes.ContentState {
         DamagoWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DamagoWidgetAttributes.preview) {
   DamagoWidgetLiveActivity()
} contentStates: {
    DamagoWidgetAttributes.ContentState.smiley
    DamagoWidgetAttributes.ContentState.starEyes
}
