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

    private let charactrerSize: CGFloat = 80
    private let largeIconSize: CGFloat = 26
    private let smallIconSize: CGFloat = 20

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
                expandedCenterContentView(context: context)
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

    @ViewBuilder
    private func expandedCenterContentView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        switch context.state.screen {
        case .idle, .none:
            idleExpandedContentView(context: context)
        case .choosePokeMessage:
            choosePokeMessageView(context: context)
        case .sending:
            sendingView()
        case .error:
            errorView()
        }
    }

    private func idleExpandedContentView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        HStack(spacing: .spacingL) {
            DynamicIslandIconImage(
                for: context.state.largeImageName,
                size: charactrerSize
            )
            .clipShape(Rectangle())
            actionButtonsView(
                activityID: context
                    .activityID
            )
        }
    }

    @ViewBuilder
    private func expandedBottomView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        switch context.state.screen {
        case .idle, .none:
            HStack {
                Text("포만감")
                linearProgressView(
                    startAt: context.state.lastFedAtDate,
                    timeInterval: DamagoAttributes.feedCooldown
                )
            }
            .padding(.horizontal, .spacingXL)
        default:
            EmptyView()
        }
    }

    private func compactLeadingView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        ZStack {
            circularProgressView(
                startAt: context.state.lastFedAtDate,
                timeInterval: TimeInterval(DamagoAttributes.feedCooldown)
            )
            .frame(width: largeIconSize, height: largeIconSize)
            DynamicIslandIconImage(
                for: context.state.iconImageName,
                size: smallIconSize
            )
                .clipShape(Rectangle())
        }
    }

    private func compactTrailingView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        DynamicIslandIconImage(
            for: context.state.statusImageName,
            size: largeIconSize
        )
            .clipShape(Circle())
    }

    private func minimalView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        ZStack {
            circularProgressView(
                startAt: context.state.lastFedAtDate,
                timeInterval: TimeInterval(DamagoAttributes.feedCooldown)
            )
            .frame(width: largeIconSize, height: largeIconSize)
            DynamicIslandIconImage(
                for: context.state.iconImageName,
                size: smallIconSize
            )
                .clipShape(Rectangle())
        }
    }

    // MARK: ButtonView

    private func actionButtonsView(activityID: String) -> some View {
        VStack(spacing: .spacingS) {
            feedButton(activityID: activityID)
            pokeButton(activityID: activityID)
        }
    }

    private func feedButton(activityID: String) -> some View {
        Button(intent: FeedAppIntent(activityID: activityID)) {
            HStack(spacing: .spacingS) {
                Image(systemName: "fork.knife")
                    .foregroundStyle(feedButtonIconColor)
                Text("밥 주기")
                    .foregroundStyle(.white)
            }
        }
        .dynamicIslandActionButton(backgroundColor: feedButtonBackgroundColor)
    }

    private func pokeButton(activityID: String) -> some View {
        Button(intent: ChoosePokeMessageAppIntent(activityID: activityID)) {
            HStack(spacing: .spacingS) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.white)
                Text("콕 찌르기")
                    .foregroundStyle(.white)
            }
        }
        .dynamicIslandActionButton(backgroundColor: pokeButtonBackgroundColor)
    }

    // MARK: PokeButtonView

    private func choosePokeMessageView(context: ActivityViewContext<DamagoAttributes>) -> some View {
        let defaultItems: [(summary: String, message: String)] = [
            ("❤️", "사랑해"),
            ("안녕", "안녕!"),
            ("사랑해", "오늘도 사랑해"),
            ("보고싶어", "얼른 보고 싶다"),
            ("밥챙겨먹어", "밥 맛있게 먹어")
        ]
        var items: [(summary: String, message: String)] {
            guard let data = AppGroupUserDefaults.sharedDefaults().data(
                forKey: AppGroupUserDefaults.shortcutsKey
            ),
                  let shortcuts = try? JSONDecoder().decode([PokeShortcut].self, from: data) else {
                return defaultItems
            }
            return shortcuts.map { shortcuts in
                (shortcuts.summary, shortcuts.message)
            }
        }

        return VStack(alignment: .leading, spacing: .spacingS) {
            LazyVGrid(
                columns: [GridItem](repeating: GridItem(.flexible(), spacing: .spacingS), count: 3),
                spacing: .spacingS
            ) {
                ForEach(items, id: \.self.summary) { item in
                    Button(
                        intent: PokeWithMessageAppIntent(
                            activityID: context.activityID,
                            message: item.message
                        )
                    ) {
                        Text(item.summary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(.white)
                    }
                }
                Button(intent: BackToIdleAppIntent(activityID: context.activityID)) {
                    Text("뒤로")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundStyle(.white)
                }
                .tint(.pink)
            }
        }
    }

    private func sendingView() -> some View {
        VStack(alignment: .center, spacing: .spacingS) {
            Text("전송 중…")
                .font(.system(size: .spacingM, weight: .semibold))
                .foregroundStyle(.white)
            Text("잠시만 기다려 주세요")
                .font(.system(size: .spacingS, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func errorView() -> some View {
        VStack(alignment: .center, spacing: .spacingS) {
            Text("실패")
                .font(.system(size: .spacingM, weight: .semibold))
                .foregroundStyle(.white)
            Text("요청을 처리하지 못했습니다")
                .font(.system(size: .spacingS, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: ProgressView

    private func circularProgressView(
        startAt: Date?,
        timeInterval: TimeInterval
    ) -> some View {
        Group {
            if let startAt {
                ProgressView(
                    timerInterval: startAt...startAt.addingTimeInterval(timeInterval),
                    label: { EmptyView() },
                    currentValueLabel: { EmptyView() }
                )
                .progressViewStyle(.circular)
                .tint(.orange)
            }
        }
    }

    private func linearProgressView(startAt: Date?, timeInterval: TimeInterval) -> some View {
        Group {
            if let startAt {
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
    }
}

// MARK: - 버튼 모디파이어

private struct CapsuleActionButtonModifier: ViewModifier {
    let backgroundColor: Color

    func body(content: Content) -> some View {
        content
            .buttonStyle(.plain)
            .font(.system(size: .spacingM, weight: .semibold))
            .padding(.vertical, .spacingS)
            .padding(.horizontal, .spacingS + .spacingXS)
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

