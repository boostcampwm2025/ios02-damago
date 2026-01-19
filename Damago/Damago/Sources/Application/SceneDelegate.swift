//
//  SceneDelegate.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import ActivityKit
import DamagoNetwork
import AppIntents
import FirebaseAuth
import OSLog
import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var authObserver: NSObjectProtocol?

    deinit {
        if let authObserver { NotificationCenter.default.removeObserver(authObserver) }
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let userRepository = AppDIContainer.shared.resolve(UserRepositoryProtocol.self)
        let pushRepository = AppDIContainer.shared.resolve(PushRepositoryProtocol.self)
        LiveActivityManager.shared.configure(userRepository: userRepository, pushRepository: pushRepository)

        AppDependencyManager.shared.add(dependency: NetworkProviderImpl() as NetworkProvider)
        AppDependencyManager.shared.add(dependency: TokenProviderImpl() as TokenProvider)

        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        if let urlContext = connectionOptions.urlContexts.first {
            handleURL(urlContext.url)
        } else {
            setupRootViewController()
        }
        
        observeAuthenticationFailure()
        window.makeKeyAndVisible()
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url { handleURL(url) }
    }

    private func handleURL(_ url: URL) {
        guard url.scheme == "damago", url.host == "connection",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else { return }

        if Auth.auth().currentUser != nil {
            let fetchCodeUseCase = AppDIContainer.shared.resolve(FetchCodeUseCase.self)
            let connectCoupleUseCase = AppDIContainer.shared.resolve(ConnectCoupleUseCase.self)
            let connectionVM = ConnectionViewModel(
                fetchCodeUseCase: fetchCodeUseCase,
                connectCoupleUseCase: connectCoupleUseCase,
                opponentCode: code
            )
            let connectionVC = ConnectionViewController(viewModel: connectionVM)
            window?.rootViewController = connectionVC
        } else {
            let signInVM = SignInViewModel(
                signInUseCase: AppDIContainer.shared.resolve(SignInUseCase.self),
                opponentCode: code
            )
            let signInVC = SignInViewController(viewModel: signInVM)
            let navigationController = UINavigationController(rootViewController: signInVC)
            navigationController.setNavigationBarHidden(true, animated: false)
            window?.rootViewController = navigationController
        }
    }

    private func setupRootViewController() {
        if Auth.auth().currentUser != nil {
            if UserDefaults.standard.bool(forKey: "isConnected") {
                let tabBarController = TabBarViewController()
                window?.rootViewController = tabBarController
            } else {
                let connectionVM = ConnectionViewModel(
                    fetchCodeUseCase: AppDIContainer.shared.resolve(FetchCodeUseCase.self),
                    connectCoupleUseCase: AppDIContainer.shared.resolve(ConnectCoupleUseCase.self)
                )
                let connectionVC = ConnectionViewController(viewModel: connectionVM)
                window?.rootViewController = connectionVC
            }
        } else {
            let signInVM = SignInViewModel(signInUseCase: AppDIContainer.shared.resolve(SignInUseCase.self))
            let signInVC = SignInViewController(viewModel: signInVM)
            let navigationController = UINavigationController(rootViewController: signInVC)
            navigationController.setNavigationBarHidden(true, animated: false)
            window?.rootViewController = navigationController
        }
    }

    private func observeAuthenticationFailure() {
        authObserver = NotificationCenter.default.addObserver(
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
