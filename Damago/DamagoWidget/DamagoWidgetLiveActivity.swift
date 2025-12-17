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
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    DynamicIslandIconImage(for: context.state.largeImageName, size: 60)
                        .clipShape(Rectangle())
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Button("콕 찌르기") {
                        print("찔렸습니다.")
                    }
                }
            } compactLeading: {
                DynamicIslandIconImage(for: context.state.iconImageName, size: 26)
                    .clipShape(Rectangle())
            } compactTrailing: {
                DynamicIslandIconImage(for: context.state.statusImageName, size: 26)
                    .clipShape(Circle())
            } minimal: {
                DynamicIslandIconImage(for: context.state.iconImageName, size: 26)
                    .clipShape(Rectangle())
            }
        }
    }
}

extension DamagoAttributes {
    fileprivate static var preview: DamagoAttributes {
        DamagoAttributes(petName: "Base Pet")
    }
}

extension DamagoAttributes.ContentState {
    fileprivate static var base: DamagoAttributes.ContentState {
        .init(characterName: "Teddy", isHungry: false, statusMessage: "우리가 함께 키우는 작은 행복 🍀")
    }

    fileprivate static var hungry: DamagoAttributes.ContentState {
        .init(characterName: "Teddy", isHungry: true, statusMessage: "우리가 함께 키우는 작은 행복 🍀")
    }
}

#Preview("Notification", as: .content, using: DamagoAttributes.preview) {
   DamagoWidgetLiveActivity()
} contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
}
