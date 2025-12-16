//
//  SceneDelegate.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit
import ActivityKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window = window
        window.makeKeyAndVisible()
        
        startLiveActivity()
    }
    
    private func startLiveActivity() {
        guard Activity<DamagoAttributes>.activities.isEmpty else { return }
        
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let initialContentState = DamagoAttributes.ContentState(
                petImageName: "PetBase",
                statusImageName: "BaseHeart"
            )
            let activityAttributes = DamagoAttributes(petName: "Base Pet")
            
            do {
                let _ = try Activity.request(
                    attributes: activityAttributes,
                    content: .init(
                        state: initialContentState,
                        staleDate: nil
                    )
                )
            } catch {
                print("Error requesting activity: \(error.localizedDescription)")
            }
        }
    }
}
