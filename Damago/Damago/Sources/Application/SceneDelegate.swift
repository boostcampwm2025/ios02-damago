//
//  SceneDelegate.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit
import ActivityKit

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

        window.rootViewController = codeConnectionViewController
        self.window = window
        window.makeKeyAndVisible()
    }

    // 사용자가 Foreground에 돌아왔을 때 서버와 동기화
    func sceneDidBecomeActive(_ scene: UIScene) {
        LiveActivityManager.shared.synchronizeActivity()
    }
}
