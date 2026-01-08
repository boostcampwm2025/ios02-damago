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
    private let feedButtonBackgroundColor = Color(
        red: 65.0 / 255.0,
        green: 74.0 / 255.0,
        blue: 84.0 / 255.0
    )   // #414A54
    private let feedButtonIconColor = Color(
        red: 234.0 / 255.0,
        green: 208.0 / 255.0,
        blue: 73.0 / 255.0
    )        // #EAD049
    private let pokeButtonBackgroundColor = Color(
        red: 242.0 / 255.0,
        green: 113.0 / 255.0,
        blue: 182.0 / 255.0
    ) // #F271B6

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DamagoAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            dynamicIslandView(context: context)
        }
    }

    // MARK: 다이나믹 아일랜드

    private func dynamicIslandView(context: ActivityViewContext<DamagoAttributes>) -> DynamicIsland {
        DynamicIsland {
            DynamicIslandExpandedRegion(.center) {
                expandedCenterView(context: context)
            }

            DynamicIslandExpandedRegion(.bottom) {
                expandedBottomView(context: context)
            }
        } compactLeading: {
            compactLeadingView(context: context)
        } compactTrailing: {
            compactTrailingView(context: context)
        } minimal: {
            minimalView(context: context)
        }
    }

    private func expandedCenterView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        HStack(spacing: 24) {
            DynamicIslandIconImage(for: context.state.largeImageName, size: 80)
                .clipShape(Rectangle())

            actionButtonsView(udid: context.attributes.udid)
        }
    }

    private func expandedBottomView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        HStack {
            Text("소화 중")
            linearProgressView(
                startAt: context.state.lastFedAt,
                timeInterval: DamagoAttributes.feedCooldown
            )
        }
        .padding(.horizontal, 32)
    }

    private func compactLeadingView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        ZStack {
            circularProgressView(
                startAt: context.state.lastFedAt,
                timeInterval: TimeInterval(DamagoAttributes.feedCooldown)
            )
            .frame(width: 26, height: 26)
            DynamicIslandIconImage(for: context.state.iconImageName, size: 20)
                .clipShape(Rectangle())
        }
    }

    private func compactTrailingView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        DynamicIslandIconImage(for: context.state.statusImageName, size: 26)
            .clipShape(Circle())
    }

    private func minimalView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        ZStack {
            circularProgressView(
                startAt: context.state.lastFedAt,
                timeInterval: TimeInterval(DamagoAttributes.feedCooldown)
            )
            .frame(width: 26, height: 26)
            DynamicIslandIconImage(for: context.state.iconImageName, size: 20)
                .clipShape(Rectangle())
        }
    }

    // MARK: ButtonView

    private func actionButtonsView(udid: String) -> some View {
        VStack(spacing: 10) {
            feedButton(udid: udid)
            pokeButton(udid: udid)
        }
    }

    private func feedButton(udid: String) -> some View {
        Button(intent: FeedAppIntent(udid: udid)) {
            HStack(spacing: 8) {
                Image(systemName: "fork.knife")
                    .foregroundStyle(feedButtonIconColor)
                Text("밥 주기")
                    .foregroundStyle(.white)
            }
        }
        .dynamicIslandActionButton(backgroundColor: feedButtonBackgroundColor)
    }

    private func pokeButton(udid: String) -> some View {
        Button(intent: PokeAppIntent(udid: udid)) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.white)
                Text("콕 찌르기")
                    .foregroundStyle(.white)
            }
        }
        .dynamicIslandActionButton(backgroundColor: pokeButtonBackgroundColor)
    }

    // MARK: ProgressView

    private func circularProgressView(
        startAt: Date,
        timeInterval: TimeInterval,
        text: String? = nil
    ) -> some View {
        ProgressView(
            timerInterval: startAt...startAt.addingTimeInterval(timeInterval),
            label: { EmptyView() },
            currentValueLabel: { Text(text ?? "").font(.system(size: 14))}
        )
        .progressViewStyle(.circular)
        .tint(.orange)
    }

    private func linearProgressView(startAt: Date, timeInterval: TimeInterval) -> some View {
        ProgressView(
            timerInterval: startAt...startAt.addingTimeInterval(timeInterval),
            label: { EmptyView() },
            currentValueLabel: { EmptyView() }
        )
        .tint(.orange)
        .progressViewStyle(.linear)
        .scaleEffect(y: 2)
    }
}

// MARK: - 버튼 모디파이어

private struct CapsuleActionButtonModifier: ViewModifier {
    let backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .font(.system(size: 16, weight: .semibold))
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .containerRelativeFrame(.horizontal, count: 5, span: 2, spacing: 0)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
}

private extension View {
    func dynamicIslandActionButton(backgroundColor: Color) -> some View {
        modifier(CapsuleActionButtonModifier(backgroundColor: backgroundColor))
    }
}

// MARK: - 프리뷰

#if DEBUG

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
            lastFedAt: Date()
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
            lastFedAt: Date().addingTimeInterval(DamagoAttributes.feedCooldown)
        )
    }
}
#endif

#Preview("Notification", as: .content, using: DamagoAttributes.preview) {
    DamagoWidgetLiveActivity()
} contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
}

#Preview("DI - Compact",
         as: .dynamicIsland(.compact),
         using: DamagoAttributes.preview,
         widget: {
    DamagoWidgetLiveActivity()
}, contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
})

#Preview("DI - Minimal",
         as: .dynamicIsland(.minimal),
         using: DamagoAttributes.preview,
         widget: {
    DamagoWidgetLiveActivity()
}, contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
})

#Preview("DI - Expanded",
         as: .dynamicIsland(.expanded),
         using: DamagoAttributes.preview,
         widget: {
    DamagoWidgetLiveActivity()
}, contentStates: {
    DamagoAttributes.ContentState.base
    DamagoAttributes.ContentState.hungry
})
