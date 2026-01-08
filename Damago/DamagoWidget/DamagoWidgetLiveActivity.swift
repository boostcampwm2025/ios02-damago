//
//  DamagoWidgetLiveActivity.swift
//  DamagoWidget
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

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
                    Button(intent: PokeAppIntent(udid: context.attributes.udid)) {
                        Text("콕 찌르기")
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
        DamagoAttributes(petName: "Base Pet", udid: "preview-udid")
    }
}

extension DamagoAttributes.ContentState {
    fileprivate static var base: DamagoAttributes.ContentState {
        .init(
            petType: "Teddy",
            isHungry: false,
            statusMessage: "우리가 함께 키우는 작은 행복 🍀",
            level: 20,
            currentExp: 30,
            maxExp: 100,
            lastFedAt: "2026-01-08T12:00:00Z"
        )
    }

    fileprivate static var hungry: DamagoAttributes.ContentState {
        .init(
            petType: "Teddy",
            isHungry: true,
            statusMessage: "우리가 함께 키우는 작은 행복 🍀",
            level: 20,
            currentExp: 30,
            maxExp: 100,
            lastFedAt: "2026-01-08T08:00:00Z"
        )
    }
}

#Preview("Notification", as: .content, using: DamagoAttributes.preview) {
    DamagoWidgetLiveActivity()
} contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
}
