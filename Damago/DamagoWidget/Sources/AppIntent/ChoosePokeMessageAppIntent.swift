//
//  ChoosePokeMessageAppIntent.swift
//  Damago
//
//  Created by Eden Landelyse on 1/14/26.
//

import ActivityKit
import AppIntents
import Foundation
import OSLog

struct ChoosePokeMessageAppIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "찌르기 메시지 선택하기"
    static var description: IntentDescription = "상대방에게 전할 메시지를 고릅니다."
    static var openAppWhenRun: Bool = false // 26버전부터 deprecated될 예정이지만 하위 버전에서는 대체 문법을 사용할 수 없음

    @Parameter(title: "Activity ID")
    var activityID: String

    init(activityID: String) { self.activityID = activityID }
    init() {}

    func perform() async throws -> some IntentResult {
        @MainActor
        func setScreen() async {
            SharedLogger.liveActivityAppIntent.log("ChooseMessage App Intent runned")
            guard let activity = Activity<DamagoAttributes>.activities.first(where: { $0.id == activityID }) else {
                SharedLogger.liveActivityAppIntent.log("live activity id match failed: \(activityID)")
                return
            }

            var newState = activity.content.state
            newState.screen = .choosePokeMessage
            await activity.update(ActivityContent(state: newState, staleDate: nil))

        }

        await setScreen()

        return .result()
    }
}
