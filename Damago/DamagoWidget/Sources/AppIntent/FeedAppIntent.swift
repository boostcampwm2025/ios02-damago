//
//  FeedAppIntent.swift
//  Damago
//
//  Created by Eden Landelyse on 1/8/26.
//

import AppIntents
import Foundation
import DamagoNetwork
import OSLog
import ActivityKit

struct FeedAppIntent: AppIntent, LiveActivityIntent {
    static var title: LocalizedStringResource = "밥 주기"
    static var description: IntentDescription = "다마고에게 밥을 줍니다."

    @Parameter(title: "Live Activity ID")
    var activityID: String

    @Dependency var networkProvider: NetworkProvider
    @Dependency var tokenProvider: TokenProvider

    init() { }

    init(activityID: String) {
        self.activityID = activityID
    }

    func perform() async throws -> some IntentResult {
        await setScreen(.sending)

        do {
            let token = try await fetchIDToken()
            let userInfo = try await fetchUserInfo(accessToken: token)

            guard let damagoID = userInfo.damagoID else {
                await showTransientErrorAndReturnIdle(logMessage: "User info doesn't have damago id")
                return .result()
            }

            try await requestFeed(accessToken: token, damagoID: damagoID)

            // feed 성공 후 서버의 최신 PetStatus로 Live Activity 상태 동기화
            guard let petStatus = try await fetchPetStatus(accessToken: token) else {
                await showTransientErrorAndReturnIdle()
                return .result()
            }

            await applyPetStatusAndReturnIdle(petStatus)
            return .result()
        } catch {
            await SharedLogger.liveActivityAppIntent
                .error("Feed request failed: \(String(describing: error))")

            await showTransientErrorAndReturnIdle()
            return .result()
        }
    }

    /// 현재 Live Activity를 찾아서, 최신 ContentState를 가져온 뒤 변경을 적용하고 업데이트합니다.
    @MainActor
    private func updateState(_ mutate: (inout DamagoAttributes.ContentState) -> Void) async {
        guard let activity = Activity<DamagoAttributes>.activities.first(where: { $0.id == activityID }) else {
            SharedLogger.liveActivityAppIntent
                .error("live activity id match failed: \(activityID)")
            return
        }

        var next = activity.content.state
        mutate(&next)

        await activity.update(ActivityContent(state: next, staleDate: nil))
    }

    /// Live Activity 화면 상태(`screen`)만 변경합니다.
    private func setScreen(_ screen: DamagoAttributes.Screen) async {
        await updateState { $0.screen = screen }
    }

    /// 인증 토큰(ID Token)을 가져옵니다.
    private func fetchIDToken() async throws -> String {
        try await tokenProvider.idToken()
    }

    /// 사용자 정보를 서버에서 조회합니다.
    private func fetchUserInfo(accessToken: String) async throws -> UserInfoResponse {
        try await networkProvider.request(
            UserAPI.getUserInfo(accessToken: accessToken)
        )
    }

    /// 서버에 feed 요청을 전송합니다.
    private func requestFeed(accessToken: String, damagoID: String) async throws {
        _ = try await networkProvider.requestSuccess(
            PetAPI.feed(accessToken: accessToken, damagoID: damagoID)
        )
    }

    /// 최신 PetStatus를 얻기 위해 UserInfo를 재조회하고, petStatus만 반환합니다.
    /// - Returns: 서버 응답에 petStatus가 없으면 nil을 반환합니다.
    private func fetchPetStatus(accessToken: String) async throws -> DamagoStatusResponse? {
        let refreshedUserInfo: UserInfoResponse = try await fetchUserInfo(accessToken: accessToken)

        guard let petStatus = refreshedUserInfo.petStatus else {
            await SharedLogger.liveActivityAppIntent
                .error("User info doesn't have pet status")
            return nil
        }

        return petStatus
    }

    /// 서버에서 받은 PetStatus로 ContentState를 재구성하고, 화면을 idle로 복귀시킵니다.
    private func applyPetStatusAndReturnIdle(_ petStatus: DamagoStatusResponse) async {
        await updateState { state in
            state = DamagoAttributes.ContentState(
                petType: petStatus.petType,
                isHungry: petStatus.isHungry,
                statusMessage: petStatus.statusMessage,
                level: petStatus.level,
                currentExp: petStatus.currentExp,
                maxExp: petStatus.maxExp,
                lastFedAt: petStatus.lastFedAt?.ISO8601Format()
            )
            state.screen = .idle
        }
    }

    /// 에러 화면을 잠깐 노출한 뒤, idle로 복귀시킵니다.
    private func showTransientErrorAndReturnIdle(
        logMessage: String? = nil,
        delayNanoseconds: UInt64 = 1_200_000_000
    ) async {
        if let logMessage {
            await SharedLogger.liveActivityAppIntent.error("\(logMessage)")
        }

        await setScreen(.error)
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        await setScreen(.idle)
    }
}
