//
//  AppDelegate.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging
import OSLog
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// 앱이 처음 실행될 때 호출되는 메소드입니다.
    /// Firebase 설정, 알림 권한 요청, Delegate 연결 등의 초기화 작업을 수행합니다.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. Firebase SDK 초기화 (가장 먼저 실행되어야 함)
        FirebaseApp.configure()

        do {
            try Auth.auth().useUserAccessGroup("B3PWYBKFUK.kr.codesquad.boostcamp10.Damago.SharedKeychain")
        } catch {
            SharedLogger.firebase.error("키체인 그룹 에러: \(error.localizedDescription)")
        }

        setupFirebaseEmulators()

        // 2. iOS 기본 알림 센터(UNUserNotificationCenter) delegate 설정
        // -> 앱이 켜져 있을 때 알림을 어떻게 처리할지 결정하기 위함
        UNUserNotificationCenter.current().delegate = self

        // 3. 사용자에게 알림 권한 요청 (알림, 뱃지, 사운드)
        // -> 앱 최초 실행 시 "알림을 허용하시겠습니까?" 팝업이 뜹니다.
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        Task {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
                SharedLogger.apns.info("알림 권한 허용 여부: \(granted)")
            } catch {
                SharedLogger.apns.error("알림 권한 요청 에러: \(error)")
            }
        }

        // 4. Apple Push Notification Service(APNs)에 기기 등록
        // -> Apple 서버로부터 디바이스 고유 토큰(Device Token)을 받기 위함
        application.registerForRemoteNotifications()

        // 5. Firebase Messaging 대리자 설정
        // -> FCM 토큰 생성 및 갱신 이벤트를 감지하기 위함
        Messaging.messaging().delegate = self

        // 라이브 액티비티 원격 실행을 위한 토큰 감시
        LiveActivityManager.shared.startMonitoring()

        // 의존성 등록
        let assembler = AppAssembler()
        assembler.assemble(AppDIContainer.shared)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - UNUserNotificationCenterDelegate (Apple 알림 처리)
/// iOS 시스템 차원의 알림 이벤트를 처리하는 Extension입니다.
extension AppDelegate: UNUserNotificationCenterDelegate {

    /// Apple(APNs)에서 기기 고유 토큰(Device Token)을 성공적으로 발급받았을 때 호출됩니다.
    /// - Parameter deviceToken: Apple이 발급한 이진 데이터 형태의 토큰
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        SharedLogger.apns.info("✅ APNs token retrieved: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")

        // 발급받은 APNs 토큰을 Firebase Messaging에 연결합니다.
        // 이 과정이 없으면 Firebase Console이나 API로 보낸 푸시가 기기에 도착하지 않습니다.
        Messaging.messaging().apnsToken = deviceToken
    }

    /// Apple(APNs)에서 기기 고유 토큰(Device Token)의 발급이 실패했을 때 호출됩니다.
    /// - Parameter deviceToken: Apple이 발급한 이진 데이터 형태의 토큰
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        // TODO: - 유저 피드백 제공
        // ex) Alert와 함께 앱 종료
    }

    /// 앱이 **화면(Foreground)**에 켜져 있는 상태에서 푸시 알림이 왔을 때 호출됩니다.
    /// - 기본적으로 iOS는 앱을 보고 있을 때 알림을 숨기지만, 이 설정을 통해 배너를 띄울 수 있습니다.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // .banner: 상단 배너 표시, .list: 알림 센터에 표시, .sound: 소리 재생
        completionHandler([.list, .banner, .sound])
    }
}

// MARK: - MessagingDelegate (Firebase 토큰 처리)
/// Firebase의 자체 토큰 관리 이벤트를 처리하는 확장입니다.
extension AppDelegate: MessagingDelegate {
    /// FCM 등록 토큰(Registration Token)이 갱신되거나 최초 생성될 때 호출됩니다.
    /// - Parameter fcmToken: **서버(Cloud Function/Firestore)에 저장해야 할 실제 주소 값**입니다.
    /// - Note: 앱을 지웠다 깔거나, 새 기기에서 로그인할 때 갱신될 수 있습니다.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        SharedLogger.apns.info("🔥 Firebase registration token: \(String(describing: fcmToken))")

        UserDefaults.standard.set(fcmToken, forKey: "fcmToken")

        NotificationCenter.default.post(name: .fcmTokenDidUpdate, object: nil)

        guard let fcmToken else { return }

        Task {
            let useCase = AppDIContainer.shared.resolve(UpdateFCMTokenUseCase.self)
            do {
                try await useCase.execute(fcmToken: fcmToken)
                SharedLogger.apns.info("✅ FCM token 업데이트 완료")
            } catch {
                SharedLogger.apns.error("❌ FCM token 업데이트 실패: \(error.localizedDescription)")
            }
        }
    }
}

extension AppDelegate {
    func setupFirebaseEmulators() {
#if DEBUG
        guard let localIP = ProcessInfo.processInfo.environment["USE_LOCAL_EMULATOR"] else { return }

        // Firestore Emulator
        Firestore.firestore().useEmulator(withHost: localIP, port: 8080)
        let settings = Firestore.firestore().settings
        settings.isSSLEnabled = false
        Firestore.firestore().settings = settings

        // Auth Emulator
        Auth.auth().useEmulator(withHost: localIP, port: 9099)
#endif
    }
}
