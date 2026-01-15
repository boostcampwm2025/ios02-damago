//
//  BackToIdleAppIntent.swift
//  Damago
//
//  Created by Eden Landelyse on 1/14/26.
//

import AppIntents
import ActivityKit

struct BackToIdleAppIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "뒤로가기"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Activity ID")
    var activityID: String

    init(activityID: String) { self.activityID = activityID }
    init() {}

    func perform() async throws -> some IntentResult {

        @MainActor
        func setScreen() async {
            guard let activity = Activity<DamagoAttributes>.activities.first(where: { $0.id == activityID }) else {
                return
            }

            var newState = activity.content.state
            newState.screen = .idle
            await activity.update(ActivityContent(state: newState, staleDate: nil))
        }

        await setScreen()

        return .result()
    }
}
