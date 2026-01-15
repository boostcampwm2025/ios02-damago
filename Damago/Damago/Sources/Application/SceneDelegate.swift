//
//  SceneDelegate.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import DamagoNetwork
import FirebaseAuth
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let userRepository = AppDIContainer.shared.resolve(UserRepositoryProtocol.self)
        let pushRepository = AppDIContainer.shared.resolve(PushRepositoryProtocol.self)
        LiveActivityManager.shared.configure(userRepository: userRepository, pushRepository: pushRepository)

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        setupRootViewController()
        observeAuthenticationFailure()
        window.makeKeyAndVisible()
    }

    private func setupRootViewController() {
        if Auth.auth().currentUser != nil {
            let tabBarController = TabBarViewController()
            window?.rootViewController = tabBarController
        } else {
            let signInVM = SignInViewModel(signInUseCase: AppDIContainer.shared.resolve(SignInUseCase.self))
            let signInVC = SignInViewController(viewModel: signInVM)
            let navigationController = UINavigationController(rootViewController: signInVC)
            navigationController.setNavigationBarHidden(true, animated: false)
            window?.rootViewController = navigationController
        }
    }

    private func observeAuthenticationFailure() {
        NotificationCenter.default.addObserver(
            forName: .authenticationDidFail,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupRootViewController()
        }
    }

    // 사용자가 Foreground에 돌아왔을 때 서버와 동기화
    func sceneDidBecomeActive(_ scene: UIScene) {
        LiveActivityManager.shared.synchronizeActivity()
    }
}
