//
//  LiveActivityManager.swift
//  Damago
//
//  Created by 김재영 on 12/17/25.
//

import Foundation
import ActivityKit
import OSLog
import UIKit

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
                petType: activityData.petType,
                isHungry: activityData.isHungry,
                statusMessage: activityData.statusMessage,
                level: activityData.level,
                currentExp: activityData.currentExp,
                maxExp: activityData.maxExp
            )
            let attributes = DamagoAttributes(
                petName: activityData.petName,
                udid: UIDevice.current.identifierForVendor?.uuidString ?? "Not Available"
            )

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
        guard let udid = UIDevice.current.identifierForVendor?.uuidString else {
            completion(nil)
            return
        }
        
        Task {
            guard let url = URL(string: "\(BaseURL.string)/get_user_info") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONEncoder().encode(["udid": udid])
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    SharedLogger.liveActivityManger.error("정보 조회 실패")
                    completion(nil)
                    return
                }
                
                let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
                
                guard let status = userInfo.petStatus else {
                    SharedLogger.liveActivityManger.error("활성화된 펫 정보 없음")
                    completion(nil)
                    return
                }
                
                let activityData = ActivityData(
                    petName: status.petName,
                    petType: status.petType,
                    isHungry: status.isHungry,
                    statusMessage: status.statusMessage,
                    level: status.level,
                    currentExp: status.currentExp,
                    maxExp: status.maxExp
                )
                
                completion(activityData)
                
            } catch {
                SharedLogger.liveActivityManger.error("네트워크 에러: \(error)")
                completion(nil)
            }
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
        SharedLogger.liveActivityManger.info("💥 서버로 전송할 시작용 Push Token: \(token)")
        requestSaveToken(token: token, key: "laStartToken")
    }

    private func sendUpdateTokenToServer(token: String) {
        SharedLogger.liveActivityManger.info("🤝 서버로 전송할 업데이트용 Push Token: \(token)")
        requestSaveToken(token: token, key: "laUpdateToken")
    }
    
    private func requestSaveToken(token: String, key: String) {
        guard let url = URL(string: "\(BaseURL.string)/save_live_activity_token"),
              let udid = UIDevice.current.identifierForVendor?.uuidString else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "udid": udid,
            key: token
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            SharedLogger.liveActivityManger.error("토큰 변환에 실패했습니다: \(error)")
            return
        }
        
        Task {
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                    SharedLogger.liveActivityManger.error("서버 응답에 문제가 있었습니다: \(httpResponse.statusCode) for key: \(key)")
                } else {
                    SharedLogger.liveActivityManger.info("토큰 저장에 성공했습니다: \(key)")
                }
            } catch {
                SharedLogger.liveActivityManger.error("토큰 저장에 실패했습니다: \(error)")
            }
        }
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
