//
//  DamagoWidgetLiveActivity.swift
//  DamagoWidget
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DamagoWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DamagoAttributes.self) { context in
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

extension DamagoAttributes {
    fileprivate static var preview: DamagoAttributes {
        DamagoAttributes(name: "World")
    }
}

extension DamagoAttributes.ContentState {
    fileprivate static var smiley: DamagoAttributes.ContentState {
        DamagoAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DamagoAttributes.ContentState {
         DamagoAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DamagoAttributes.preview) {
   DamagoWidgetLiveActivity()
} contentStates: {
    DamagoAttributes.ContentState.smiley
    DamagoAttributes.ContentState.starEyes
}
