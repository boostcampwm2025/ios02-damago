//
//  ViewController.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit
import os

@MainActor
final class ViewController: UIViewController {
    private var hasStartedAnimation = false
    private var isShowingTouchAnimation = false
    private var currentDamagoID: String?
    
    private let spriteAnimationView: SpriteAnimationView = {
        let view = SpriteAnimationView(defaultDamagoName: "PuppyBark")
        view.translatesAutoresizingMaskIntoConstraints = false
        view.animationDuration = 1.0
        return view
    }()

    private lazy var pokeButton: UIButton = {
        let action = UIAction { [weak self] _ in self?.sendNotification() }
        let button = UIButton(type: .system, primaryAction: action)
        button.setTitle("찌르기", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var interactrionButton: UIButton = {
        let action = UIAction { [weak self] _ in
            self?.spriteAnimationView.animate(damagoName: "PuppySneak", repeatCount: 3)
        }
        let button = UIButton(type: .system, primaryAction: action)
        button.setTitle("상호작용", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var feedButton: UIButton = {
        let action = UIAction { [weak self] _ in self?.feedPet() }
        let button = UIButton(type: .system, primaryAction: action)
        button.setTitle("먹이주기", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(spriteAnimationView)
        view.addSubview(pokeButton)
        view.addSubview(interactrionButton)
        view.addSubview(feedButton)

        NSLayoutConstraint.activate([
            pokeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            pokeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            interactrionButton.topAnchor.constraint(equalTo: pokeButton.bottomAnchor, constant: 16),
            interactrionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            feedButton.topAnchor.constraint(equalTo: interactrionButton.bottomAnchor, constant: 20),
            feedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            spriteAnimationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spriteAnimationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spriteAnimationView.widthAnchor.constraint(equalToConstant: 300),
            spriteAnimationView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        fetchUserInfo()
    }
}

extension ViewController {
    var udid: String? { UIDevice.current.identifierForVendor?.uuidString }

    private func sendNotification() {
        Task {
            guard let url = URL(string: "\(BaseURL.string)/poke") else { return }

            var request = URLRequest(url: url)
            let body = ["udid": udid]

            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.invalidResponse }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw NetworkError.invalidStatusCode(
                    httpResponse.statusCode,
                    String(data: data, encoding: .utf8) ?? "invalid data"
                )
            }
        }
    }

    private func feedPet() {
        Task {
            guard let damagoID = currentDamagoID else {
                SharedLogger.viewController.error("❌ 아직 Damago ID를 가져오지 못했습니다.")
                return
            }
            
            guard let url = URL(string: "\(BaseURL.string)/feed") else { return }

            var request = URLRequest(url: url)
            let body = ["damagoID": damagoID]

            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)

            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else { return }
                if (200..<300).contains(httpResponse.statusCode) {
                    SharedLogger.viewController.info("✅ 먹이주기 성공: \(String(data: data, encoding: .utf8) ?? "")")
                    LiveActivityManager.shared.synchronizeActivity()
                } else {
                    SharedLogger.viewController.error("❌ 먹이주기 실패: \(httpResponse.statusCode)")
                }
            } catch {
                SharedLogger.viewController.error("❌ 네트워크 에러: \(error)")
            }
        }
    }
    
    private func fetchUserInfo() {
        Task {
            guard let url = URL(string: "\(BaseURL.string)/get_user_info") else { return }
            
            var request = URLRequest(url: url)
            let body = ["udid": udid]
            
            request.httpMethod = "POST"
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) else {
                    SharedLogger.viewController.error("❌ 유저 정보 가져오기 실패")
                    return
                }
                
                let userInfo = try JSONDecoder().decode(UserInfoResponse.self, from: data)
                self.currentDamagoID = userInfo.damagoID
                SharedLogger.viewController.info("✅ 내 다마고 ID 확인: \(userInfo.damagoID ?? "없음")")
                
                // 펫 정보가 확인되면 Live Activity 동기화 (시작)
                if userInfo.damagoID != nil {
                    LiveActivityManager.shared.synchronizeActivity()
                }
                
            } catch {
                SharedLogger.viewController.error("❌ 유저 정보 가져오기 에러: \(error)")
            }
        }
    }
}
