//
//  LiveActivityManager.swift
//  Damago
//
//  Created by 김재영 on 12/17/25.
//

import Foundation
import ActivityKit
import OSLog

struct ActivityData {
    let petName: String
    let characterName: String
    var isHungry: Bool
    var statusMessage: String
}

final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private var monitoredActivityIDs: Set<String> = []

    func synchronizeActivity() {
        fetchActivityData { activityData in
            guard let activityData else {
                // 서버로 받은 데이터가 없으면 실행 중인 모든 Live Activity를 종료합니다.
                self.endAllActivities()
                return
            }

            let latestContentState = DamagoAttributes.ContentState(
                characterName: activityData.characterName,
                isHungry: activityData.isHungry,
                statusMessage: activityData.statusMessage
            )
            let attributes = DamagoAttributes(petName: activityData.petName)

            if let activity = Activity<DamagoAttributes>.activities.first {
                Task {
                    await activity.update(.init(state: latestContentState, staleDate: nil))
                }
            } else {
                self.startActivity(attributes: attributes, contentState: latestContentState)
            }
        }
    }
    
    func startMonitoring() {
        startMonitoringPushToStartToken()
        monitoringLiveActivities()
    }

    private func fetchActivityData(completion: @escaping (ActivityData?) -> Void) {
        // TODO: 서버의 데이터로부터 가져오도록 수정
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let mockData = ActivityData(
                petName: "곰곰이",
                characterName: "Teddy",
                isHungry: false,
                statusMessage: "우리가 함께 키우는 작은 행복 🍀"
            )
            completion(mockData)
        }
    }
    
    private func startMonitoringPushToStartToken() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if #available(iOS 17.2, *) {
            Task {
                for await pushToken in Activity<DamagoAttributes>.pushToStartTokenUpdates {
                    let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                    self.sendStartTokenToServer(token: tokenString)
                }
            }
        }
    }
    
    private func monitoringLiveActivities() {
        Task {
            // 이미 실행 중인 액티비티 감시
            for activity in Activity<DamagoAttributes>.activities {
                monitorPushToken(activity)
            }
            
            // 앞으로 생기거나 시스템에 의해 생성되는 액티비티 감시
            for await activity in Activity<DamagoAttributes>.activityUpdates {
                monitorPushToken(activity)
            }
        }
    }

    private func startActivity(attributes: DamagoAttributes, contentState: DamagoAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: .token
            )
            
            monitorPushToken(activity)
        } catch {
            SharedLogger.liveActivityManger.error("Failed to request Live Activity. Error: \(error)")
        }
    }

    private func endAllActivities() {
        Task {
            for activity in Activity<DamagoAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            SharedLogger.liveActivityManger.info("All Live Activities have been ended.")
        }
    }

    private func sendStartTokenToServer(token: String) {
        print("💥 서버로 전송할 시작용 Push Token: \(token)")
        // TODO: 서버와 통신하여 이 토큰을 저장하는 네트워크 코드 구현
    }

    private func sendUpdateTokenToServer(token: String) {
        print("🤝 서버로 전송할 업데이트용 Push Token: \(token)")
        // TODO: 서버와 통신하여 이 토큰을 저장하는 네트워크 코드 구현
    }
    
    private func monitorPushToken(_ activity: Activity<DamagoAttributes>) {
        guard !monitoredActivityIDs.contains(activity.id) else { return }
        
        monitoredActivityIDs.insert(activity.id)
        
        Task {
            for await pushToken in activity.pushTokenUpdates {
                let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                self.sendUpdateTokenToServer(token: tokenString)
            }
            monitoredActivityIDs.remove(activity.id)
        }
    }
}
