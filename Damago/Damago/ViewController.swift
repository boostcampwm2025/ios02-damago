//
//  ViewController.swift
//  Damago
//
//  Created by 김재영 on 12/16/25.
//

import UIKit
import Gifu
import ImageIO
import OSLog

@MainActor
final class ViewController: UIViewController {
    private var isShowingTouchAnimation = false
    private var currentDamagoID: String?
    
    private let gifImageView: GIFImageView = {
        let imageView = GIFImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    private lazy var pokeButton: UIButton = {
        let action = UIAction { [weak self] _ in self?.sendNotification() }
        let button = UIButton(type: .system, primaryAction: action)
        button.setTitle("찌르기", for: .normal)
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
        
        view.addSubview(gifImageView)
        view.addSubview(pokeButton)
        view.addSubview(feedButton)

        NSLayoutConstraint.activate([
            pokeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            pokeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            feedButton.topAnchor.constraint(equalTo: pokeButton.bottomAnchor, constant: 20),
            feedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            gifImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gifImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gifImageView.widthAnchor.constraint(equalToConstant: 200),
            gifImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        setupTapGesture()
        gifImageView.animate(withGIFNamed: "dog")
        
        fetchUserInfo()
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGifTapAction(_:)))
        gifImageView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func handleGifTapAction(_ sender: UITapGestureRecognizer) {
        guard !isShowingTouchAnimation else { return }
        
        isShowingTouchAnimation = true
        gifImageView.stopAnimatingGIF()
        gifImageView.animate(withGIFNamed: "dog_touch")
        
        // dog_touch GIF의 실제 재생 시간을 가져와서 한 번만 재생
        let duration = getGIFDuration(named: "dog_touch")
        
        Task {
            try? await Task.sleep(for: .seconds(duration))
            isShowingTouchAnimation = false
            gifImageView.stopAnimatingGIF()
            gifImageView.animate(withGIFNamed: "dog")
        }
    }
}

extension ViewController {
    private func getGIFDuration(named: String) -> TimeInterval {
        // 번들에서 GIF 파일 URL 가져오기
        guard let url = Bundle.main.url(forResource: named, withExtension: "gif"),
              let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            return 1.5 // 기본값
        }
        
        // GIF의 총 프레임 수 확인
        let frameCount = CGImageSourceGetCount(source)
        var totalDuration: TimeInterval = 0
        
        // 각 프레임의 딜레이 시간을 합산하여 총 재생 시간 계산
        for index in 0..<frameCount {
            guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
                  let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                  let delayTime = gifProperties[kCGImagePropertyGIFDelayTime as String] as? Double else {
                continue
            }
            totalDuration += delayTime
        }
        
        // 계산된 시간이 있으면 반환, 없으면 기본값 반환
        return totalDuration > 0 ? totalDuration : 1.5
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
