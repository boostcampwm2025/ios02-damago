//
//  SceneDelegate.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit
import ActivityKit
import OSLog

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        let codeConnectionViewModel = CodeConnectionViewModel()
        let codeConnectionViewController = CodeConnectionViewController(
            viewModel: codeConnectionViewModel
        )

        let navigationViewController = UINavigationController(
            rootViewController: codeConnectionViewController
        )
        window.rootViewController = navigationViewController
        self.window = window
        window.makeKeyAndVisible()
        
        startLiveActivity()
    }
    
    private func startLiveActivity() {
        guard Activity<DamagoAttributes>.activities.isEmpty,
              ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let initialContentState = DamagoAttributes.ContentState(
            characterName: "Teddy",
            isHungry: false,
            statusMessage: "우리가 함께 키우는 작은 행복 🍀"
        )
        let activityAttributes = DamagoAttributes(petName: "Base Pet")
        
        do {
            _ = try Activity.request(
                attributes: activityAttributes,
                content: .init(
                    state: initialContentState,
                    staleDate: nil
                )
            )
        } catch {
            SharedLogger.dynamicIsland.error("Error requesting activity: \(error)")
        }
    }
}
