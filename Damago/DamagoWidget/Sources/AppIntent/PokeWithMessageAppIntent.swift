//
//  PokeAppIntent.swift
//  DamagoWidget
//
//  Created by 박현수 on 12/18/25.
//

import AppIntents
import Foundation
import DamagoNetwork
import ActivityKit

struct PokeWithMessageAppIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "콕 찌르기"
    static var description: IntentDescription = "메시지를 선택해 콕 찌르고 돌아갑니다."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Activity ID")
    var activityID: String

    @Parameter(title: "UDID")
    var udid: String

    @Parameter(title: "Message")
    var message: String

    init(activityID: String, udid: String, message: String) {
        self.activityID = activityID
        self.udid = udid
        self.message = message
    }
    init() {}

    func perform() async throws -> some IntentResult {
        @MainActor
        func setScreen(_ screen: DamagoAttributes.Screen) async {
            guard let activity = Activity<DamagoAttributes>.activities.first(where: { $0.id == activityID }) else {
                return
            }
            var next = activity.content.state
            next.screen = screen
            await activity.update(ActivityContent(state: next, staleDate: nil))
        }

        // 1) 전송 중 화면
        await setScreen(.sending)

        let networkProvider = NetworkProvider()

        do {
            // 2) 네트워크 (메인 액터에서 하지 않음)
            try await networkProvider.requestSuccess(
                PushAPI.poke(udid: udid, message: message)
            )

            // 3) 성공: idle 복귀
            await setScreen(.idle)
        } catch {
            // 3) 실패: 에러 화면 노출
            await setScreen(.error)

            // 짧게 보여준 뒤 idle 복귀
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await setScreen(.idle)
        }

        return .result()
    }
}
