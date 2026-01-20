//
//  LockScreenLiveActivityView.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import SwiftUI
import WidgetKit

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DamagoAttributes>
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    var body: some View {
        ZStack {
            if isLuminanceReduced {
                content.saturation(0).opacity(0.6)
            } else {
                content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.8))
    }
}

private extension LockScreenLiveActivityView {
    var content: some View {
        HStack(spacing: .spacingM) {
            let firstFrame = UIImage(named: context.state.imageName)?
                .crop(rect: CGRect(origin: .zero, size: CGSize(width: 32, height: 32)))
            Image(uiImage: firstFrame!)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 0) {
                Text("다마고")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                Text("포만감")
                    .foregroundStyle(.white)
                if let lastFedAt = context.state.lastFedAtDate {
                    ProgressView(
                        timerInterval: lastFedAt...lastFedAt.addingTimeInterval(
                            DamagoAttributes.feedCooldown),
                        label: { EmptyView() },
                        currentValueLabel: { EmptyView() }
                    )
                    .progressViewStyle(.linear)
                    .tint(.orange)
                    .scaleEffect(y: 2)
                    .padding(.trailing, .spacingM)
                    .padding(.bottom, .spacingS)
                }
                /// 추후 동적으로 문구 변경
                /// 예시: "우리의 사랑이 이만큼 자랐어요! 🌱",
                /// "[애칭]님의 사랑으로 배부르는 중 💕",
                /// "꼬르륵... 밥 먹을 시간이에요! 🍚"
                Text(context.state.statusMessage)
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding(.vertical, .spacingS)
        }
    }
}
