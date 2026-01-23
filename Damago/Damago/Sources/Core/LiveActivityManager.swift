//
//  LiveActivityManager.swift
//  Damago
//
//  Created by 김재영 on 12/17/25.
//

import Foundation
import ActivityKit
import Combine
import OSLog

final class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var userRepository: UserRepositoryProtocol?
    private var pushRepository: PushRepositoryProtocol?
    private var cancellables = Set<AnyCancellable>()
    
    private var isLiveActivityEnabled: Bool = true
    
    private init() {}
    
    func configure(
        userRepository: UserRepositoryProtocol,
        pushRepository: PushRepositoryProtocol,
        globalStore: GlobalStoreProtocol
    ) {
        self.userRepository = userRepository
        self.pushRepository = pushRepository
        
        globalStore.globalState
            .map { $0.useLiveActivity }
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                self?.isLiveActivityEnabled = isEnabled
                if !isEnabled {
                    self?.endAllActivities()
                } else {
                    self?.synchronizeActivity()
                }
            }
            .store(in: &cancellables)
    }

    private var monitoredActivityIDs: Set<String> = []

    func synchronizeActivity() {
        guard isLiveActivityEnabled else {
            SharedLogger.liveActivityManger.info("Live Activity가 비활성화되어 있어 동기화를 중단합니다.")
            endAllActivities()
            return
        }
        
        // 커플 연결 상태 확인
        guard UserDefaults.standard.bool(forKey: "isConnected") else {
            // 커플 연결이 안 되어 있으면 모든 Live Activity 종료
            SharedLogger.liveActivityManger.info("커플 연결이 되어있지 않아 Live Activity를 종료합니다.")
            endAllActivities()
            return
        }
        
        fetchActivityData { petStatus in
            guard let petStatus else {
                // 서버로 받은 데이터가 없으면 실행 중인 모든 Live Activity를 종료합니다.
                self.endAllActivities()
                return
            }

            let latestContentState = DamagoAttributes.ContentState(
                petType: petStatus.petType,
                isHungry: petStatus.isHungry,
                statusMessage: petStatus.statusMessage,
                level: petStatus.level,
                currentExp: petStatus.currentExp,
                maxExp: petStatus.maxExp,
                lastFedAt: petStatus.lastFedAt?.ISO8601Format()
            )
            let attributes = DamagoAttributes(
                petName: petStatus.petName
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

    private func fetchActivityData(completion: @escaping (PetStatus?) -> Void) {
        guard let repository = userRepository else {
            completion(nil)
            return
        }
        
        Task {
            do {
                let userInfo = try await repository.getUserInfo()
                completion(userInfo.petStatus)
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
        guard let repository = pushRepository else { return }
        
        Task {
            do {
                let laStartToken = (key == "laStartToken") ? token : nil
                let laUpdateToken = (key == "laUpdateToken") ? token : nil
                
                _ = try await repository.saveLiveActivityToken(
                    startToken: laStartToken,
                    updateToken: laUpdateToken
                )
                SharedLogger.liveActivityManger.info("토큰 저장에 성공했습니다: \(key)")
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
