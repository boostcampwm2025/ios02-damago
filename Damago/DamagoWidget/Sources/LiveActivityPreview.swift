//
//  LiveActivityPreview.swift
//  Damago
//
//  Created by Eden Landelyse on 1/19/26.
//

import SwiftUI
import ActivityKit
import WidgetKit

// MARK: - 프리뷰

extension DamagoAttributes {
    fileprivate static var preview: DamagoAttributes {
        DamagoAttributes(petName: "Base Pet")
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

    fileprivate static var choosePokeMessage: DamagoAttributes.ContentState {
        .init(
            petType: "Teddy",
            isHungry: false,
            statusMessage: "메시지를 선택해 상대를 콕 찌르세요",
            level: 20,
            currentExp: 30,
            maxExp: 100,
            lastFedAt: "2026-01-08T12:00:00Z",
            screen: .choosePokeMessage
        )
    }

    fileprivate static var sending: DamagoAttributes.ContentState {
        .init(
            petType: "Teddy",
            isHungry: false,
            statusMessage: "전송 중…",
            level: 20,
            currentExp: 30,
            maxExp: 100,
            lastFedAt: "2026-01-08T12:00:00Z",
            screen: .sending
        )
    }

    fileprivate static var error: DamagoAttributes.ContentState {
        .init(
            petType: "Teddy",
            isHungry: false,
            statusMessage: "요청을 처리하지 못했습니다",
            level: 20,
            currentExp: 30,
            maxExp: 100,
            lastFedAt: "2026-01-08T12:00:00Z",
            screen: .error
        )
    }
}

#Preview("Notification", as: .content, using: DamagoAttributes.preview) {
    DamagoWidgetLiveActivity()
} contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
    DamagoAttributes.ContentState.choosePokeMessage
}

#Preview("DI - Compact",
         as: .dynamicIsland(.compact),
         using: DamagoAttributes.preview,
         widget: {
    DamagoWidgetLiveActivity()
}, contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
    DamagoAttributes.ContentState.choosePokeMessage
})

#Preview("DI - Minimal",
         as: .dynamicIsland(.minimal),
         using: DamagoAttributes.preview,
         widget: {
    DamagoWidgetLiveActivity()
}, contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
    DamagoAttributes.ContentState.choosePokeMessage
})

#Preview("DI - Expanded",
         as: .dynamicIsland(.expanded),
         using: DamagoAttributes.preview,
         widget: {
    DamagoWidgetLiveActivity()
}, contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
    DamagoAttributes.ContentState.choosePokeMessage
    DamagoAttributes.ContentState.sending
    DamagoAttributes.ContentState.error
})
